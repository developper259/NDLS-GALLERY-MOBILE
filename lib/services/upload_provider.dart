import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';

enum UploadStatus { pending, uploading, completed, failed }

class UploadItem {
  final String id;
  final File? file;
  final Uint8List? bytes;
  final String fileName;
  UploadStatus status;
  double progress;
  String? errorMessage;

  UploadItem({
    required this.id,
    this.file,
    this.bytes,
    required this.fileName,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
  });
}

class UploadProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final List<UploadItem> _queue = [];
  bool _isUploading = false;
  VoidCallback? onMediaRefresh; // Callback pour rafraîchir les médias

  List<UploadItem> get queue => _queue;

  // Définir le callback pour rafraîchir les médias
  void setMediaRefreshCallback(VoidCallback callback) {
    onMediaRefresh = callback;
  }

  Future<void> pickAndUploadFiles() async {
    try {
      print('Opening file picker...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.media,
      );

      if (result != null) {
        print('Files selected: ${result.files.length}');

        for (var platformFile in result.files) {
          try {
            final fileName = platformFile.name;

            if (platformFile.path != null) {
              // Mobile/desktop case - use file path
              final file = File(platformFile.path!);

              // Validate file exists and is readable
              if (!await file.exists()) {
                print('File does not exist: ${platformFile.path}');
                continue;
              }

              final fileSize = await file.length();
              print('File: $fileName, Size: $fileSize bytes');

              // Check file size (50MB limit from server)
              if (fileSize > 50 * 1024 * 1024) {
                print('File too large: $fileName');
                continue;
              }

              final item = UploadItem(
                id: UniqueKey().toString(),
                file: file,
                fileName: fileName,
              );
              _queue.add(item);
              print('Added to queue: $fileName');
            } else if (platformFile.bytes != null) {
              // Web case - use bytes
              final fileSize = platformFile.bytes!.length;
              print('File: $fileName, Size: $fileSize bytes');

              // Check file size (50MB limit from server)
              if (fileSize > 50 * 1024 * 1024) {
                print('File too large: $fileName');
                continue;
              }

              final item = UploadItem(
                id: UniqueKey().toString(),
                bytes: platformFile.bytes,
                fileName: fileName,
              );
              _queue.add(item);
              print('Added to queue: $fileName');
            } else {
              print('No path or bytes available for: $fileName');
            }
          } catch (e, stackTrace) {
            print('Error processing file ${platformFile.name}: $e');
            print('Stack trace: $stackTrace');
          }
        }

        notifyListeners();
        print('Starting queue processing...');
        _processQueue();
      } else {
        print('No files selected');
      }
    } catch (e, stackTrace) {
      print('Error in pickAndUploadFiles: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _processQueue() async {
    if (_isUploading || _queue.isEmpty) return;

    _isUploading = true;
    print('Starting upload queue processing...');
    bool hasCompletedUploads = false;

    while (_queue.any((item) => item.status == UploadStatus.pending)) {
      final item = _queue.firstWhere(
        (item) => item.status == UploadStatus.pending,
      );

      try {
        print('Processing upload for: ${item.fileName}');
        item.status = UploadStatus.uploading;
        notifyListeners();

        await _apiService.uploadFile(item, (progress) {
          item.progress = progress;
          notifyListeners();
        });

        item.status = UploadStatus.completed;
        item.progress = 1.0;
        item.errorMessage = null;
        hasCompletedUploads = true;
        notifyListeners();
        print('Upload completed for: ${item.fileName}');
      } catch (e, stackTrace) {
        print('Upload failed for ${item.fileName}: $e');
        print('Stack trace: $stackTrace');

        item.status = UploadStatus.failed;
        item.errorMessage = e.toString();
        item.progress = 0.0;
        notifyListeners();
      }
    }

    _isUploading = false;
    print('Upload queue processing completed');

    // Nettoyer les uploads terminés et rafraîchir les médias
    if (hasCompletedUploads) {
      _cleanupCompletedUploads();
      _refreshMedia();
    }
  }

  void _cleanupCompletedUploads() {
    // Supprimer les uploads terminés après un délai
    Future.delayed(const Duration(seconds: 2), () {
      _queue.removeWhere((item) => item.status == UploadStatus.completed);
      notifyListeners();
      print('Cleaned up completed uploads');
    });
  }

  void _refreshMedia() {
    // Rafraîchir les médias via le callback
    if (onMediaRefresh != null) {
      onMediaRefresh!();
      print('Media refreshed after upload');
    }
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
    print('Upload queue cleared');
  }

  void addToQueue(File file) {
    try {
      final fileName = file.path.split('/').last;

      // Validate file exists and is readable
      if (!file.existsSync()) {
        print('File does not exist: ${file.path}');
        return;
      }

      final fileSize = file.lengthSync();
      print('File: $fileName, Size: $fileSize bytes');

      // Check file size (50MB limit from server)
      if (fileSize > 50 * 1024 * 1024) {
        print('File too large: $fileName');
        return;
      }

      final item = UploadItem(
        id: UniqueKey().toString(),
        file: file,
        fileName: fileName,
      );
      _queue.add(item);
      notifyListeners();
      print('Added to queue: $fileName');

      // Start processing if not already uploading
      if (!_isUploading) {
        _processQueue();
      }
    } catch (e) {
      print('Error adding file to queue: $e');
    }
  }

  bool get isUploading => _isUploading;
}
