import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../app_config.dart';
import '../models/media.dart';
import '../models/album.dart';
import '../services/upload_provider.dart';
import 'package:path/path.dart' as path;

class ApiService {
  Future<dynamic> _get(String endpoint) async {
    final response = await http.get(Uri.parse(AppConfig.apiBaseUrl + endpoint));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data['data'];
      } else {
        throw Exception('API request failed: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load data from $endpoint');
    }
  }

  Future<dynamic> _post(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse(AppConfig.apiBaseUrl + endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data;
      } else {
        throw Exception('API request failed: ${data['message']}');
      }
    } else {
      throw Exception('Failed to post data to $endpoint');
    }
  }

  Future<dynamic> _put(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      Uri.parse(AppConfig.apiBaseUrl + endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data;
      } else {
        throw Exception('API request failed: ${data['message']}');
      }
    } else {
      throw Exception('Failed to put data to $endpoint');
    }
  }

  Future<dynamic> _delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse(AppConfig.apiBaseUrl + endpoint),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return data;
      } else {
        throw Exception('API request failed: ${data['message']}');
      }
    } else {
      throw Exception('Failed to delete data from $endpoint');
    }
  }

  Future<List<Media>> getMedia() async {
    final data = await _get(AppConfig.endpoints['media']!);
    return (data as List).map((json) => Media.fromJson(json)).toList();
  }

  Future<List<Album>> getAlbums() async {
    final data = await _get(AppConfig.endpoints['albums']!);
    return (data as List).map((json) => Album.fromJson(json)).toList();
  }

  Future<List<Media>> getAlbumMedia(String albumId) async {
    final data = await _get('${AppConfig.endpoints['albums']!}/$albumId/media');
    return (data as List).map((json) => Media.fromJson(json)).toList();
  }

  Future<List<Media>> getFavorites() async {
    // In the original client, favorites are a special album (ID: "1")
    return getAlbumMedia("1");
  }

  Future<List<Media>> getTrash() async {
    final data = await _get(AppConfig.endpoints['trash']!);
    return (data as List).map((json) => Media.fromJson(json)).toList();
  }

  Future<void> moveToTrash(String mediaId) async {
    await _delete('${AppConfig.endpoints['media']!}/$mediaId');
  }

  Future<void> restoreFromTrash(String mediaId) async {
    await _post('${AppConfig.endpoints['trash']!}/restore/$mediaId');
  }

  Future<void> deletePermanently(String mediaId) async {
    await _delete('${AppConfig.endpoints['trash']!}/$mediaId');
  }

  Future<void> emptyTrash() async {
    await _delete(AppConfig.endpoints['trash']!);
  }

  Future<void> addMediaToAlbum(String albumId, String mediaId) async {
    await _post(
      '${AppConfig.endpoints['albums']!}/$albumId/media',
      body: {'mediaId': mediaId},
    );
  }

  Future<dynamic> createAlbum(String name) async {
    return await _post(AppConfig.endpoints['albums']!, body: {'name': name});
  }

  Future<dynamic> deleteAlbum(String albumId) async {
    return await _delete('${AppConfig.endpoints['albums']!}/$albumId');
  }

  Future<dynamic> renameAlbum(String albumId, String newName) async {
    return await _put(
      '${AppConfig.endpoints['albums']!}/$albumId',
      body: {'name': newName},
    );
  }

  Future<void> removeMediaFromAlbum(String albumId, String mediaId) async {
    // The original API uses a DELETE request with a body, which is not standard.
    // For now, we'll assume the server can handle it or this might need adjustment.
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.endpoints['albums']!}/$albumId/media',
    );
    final request = http.Request('DELETE', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = json.encode({'mediaId': mediaId});
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Failed to remove media from album');
    }
  }

  Future<void> setMediaFavorite(Media media) async {
    await addMediaToAlbum('1', media.id); // FAVORITES_ALBUM_ID = "1"
  }

  Future<void> removeMediaFavorite(Media media) async {
    await removeMediaFromAlbum('1', media.id); // FAVORITES_ALBUM_ID = "1"
  }

  Future<void> downloadMedia(Media media) async {
    // For Flutter, we'll return the download URL
    // The actual download will be handled by the UI layer
    // Note: In Flutter, you'd use url_launcher or similar package
  }

  Future<void> uploadFile(
    UploadItem uploadItem,
    Function(double) onProgress,
  ) async {
    print('Starting upload for file: ${uploadItem.fileName}');

    final uri = Uri.parse(
      AppConfig.apiBaseUrl + AppConfig.endpoints['upload']!,
    );
    print('Upload URL: $uri');

    // Create FormData like the web client
    final request = http.MultipartRequest('POST', uri);
    // Don't set Content-Type header - let http package set it automatically with boundary

    // Add file to FormData with field name 'files' (same as web client)
    try {
      http.MultipartFile multipartFile;

      if (uploadItem.file != null) {
        // Mobile/desktop case - use file path
        print('Using file path: ${uploadItem.file!.path}');
        print('File size: ${await uploadItem.file!.length()} bytes');

        // Detect content type based on file extension
        final contentType = _getContentType(uploadItem.fileName);

        multipartFile = await http.MultipartFile.fromPath(
          'files', // Same field name as web client
          uploadItem.file!.path,
          contentType: contentType,
        );
      } else if (uploadItem.bytes != null) {
        // Web case - use bytes
        print('Using bytes: ${uploadItem.bytes!.length} bytes');

        // Detect content type based on file extension
        final contentType = _getContentType(uploadItem.fileName);

        multipartFile = http.MultipartFile.fromBytes(
          'files', // Same field name as web client
          uploadItem.bytes!,
          filename: uploadItem.fileName,
          contentType: contentType,
        );
      } else {
        throw Exception('No file or bytes available in upload item');
      }

      request.files.add(multipartFile);
      print('File added to FormData');
    } catch (e) {
      print('Error creating multipart file: $e');
      onProgress(0.0);
      rethrow;
    }

    try {
      print('Sending FormData request...');
      final streamedResponse = await request.send();
      print('Response status code: ${streamedResponse.statusCode}');

      final response = await http.Response.fromStream(streamedResponse);
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse the response to check for success
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            onProgress(1.0); // Mark as complete
            print('Upload successful');
          } else {
            final errorMessage = responseData['message'] ?? 'Upload failed';
            print('Upload failed: $errorMessage');
            throw Exception(errorMessage);
          }
        } catch (e) {
          print('Error parsing response: $e');
          print('Response was: ${response.body}');
          throw Exception('Invalid response format: $e');
        }
      } else {
        // Parse error response
        String errorMessage = 'Failed to upload file';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // If response is not JSON, use status code
          errorMessage =
              'Upload failed with status ${response.statusCode}: ${response.body}';
        }
        print('Upload error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Upload exception: $e');
      onProgress(0.0); // Reset progress on error
      rethrow;
    }
  }

  // Helper method to get content type based on file extension
  MediaType _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.webp':
        return MediaType('image', 'webp');
      case '.mp4':
        return MediaType('video', 'mp4');
      case '.mov':
        return MediaType('video', 'quicktime');
      case '.avi':
        return MediaType('video', 'x-msvideo');
      case '.mkv':
        return MediaType('video', 'x-matroska');
      case '.webm':
        return MediaType('video', 'webm');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
