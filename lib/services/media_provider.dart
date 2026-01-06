import 'package:flutter/material.dart';
import '../models/media.dart';
import '../models/album.dart';
import 'api_service.dart';

class MediaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Media> _media = [];
  List<Album> _albums = [];
  List<Media> _favorites = [];
  List<Media> _trash = [];
  bool _isLoading = false;

  List<Media> get media => _media;
  List<Album> get albums => _albums;
  List<Media> get favorites => _favorites;
  List<Media> get trash => _trash;
  bool get isLoading => _isLoading;

  Future<void> fetchAll() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    // Simulate a small delay to ensure the loading indicator is visible
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final mediaFuture = _apiService
          .getMedia()
          .then((data) {
            _media = data;
            _media.sort((a, b) => b.creation_date.compareTo(a.creation_date));
          })
          .catchError((e) {
            // ignore: avoid_print
            print('Error fetching media: $e');
          });

      final albumsFuture = _apiService
          .getAlbums()
          .then((data) {
            _albums = data;
          })
          .catchError((e) {
            // ignore: avoid_print
            print('Error fetching albums: $e');
          });

      final favoritesFuture = _apiService
          .getFavorites()
          .then((data) {
            _favorites = data;
          })
          .catchError((e) {
            // ignore: avoid_print
            print('Error fetching favorites: $e');
          });

      final trashFuture = _apiService
          .getTrash()
          .then((data) {
            _trash = data;
          })
          .catchError((e) {
            // ignore: avoid_print
            print('Error fetching trash: $e');
          });

      await Future.wait([
        mediaFuture,
        albumsFuture,
        favoritesFuture,
        trashFuture,
      ]);
    } catch (e) {
      // Handle any other unexpected errors
      // ignore: avoid_print
      print('An unexpected error occurred: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Media media) async {
    try {
      if (media.isFavorite) {
        await _apiService.removeMediaFavorite(media);
      } else {
        await _apiService.setMediaFavorite(media);
      }
      // Refresh favorites and media list
      await fetchAll();
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<void> deleteMedia(Media media) async {
    try {
      await _apiService.moveToTrash(media.id);
      // Refresh media list
      await fetchAll();
    } catch (e) {
      print('Error deleting media: $e');
      rethrow;
    }
  }

  Future<void> addMediaToAlbum(String albumId, String mediaId) async {
    try {
      await _apiService.addMediaToAlbum(albumId, mediaId);
      // Optionally refresh album data
      await fetchAll();
    } catch (e) {
      print('Error adding media to album: $e');
      rethrow;
    }
  }

  Future<Album> createAlbum(String name) async {
    try {
      final response = await _apiService.createAlbum(name);
      // The API response might be nested, so we need to extract the album data
      final albumData = response['album'] ?? response['data'] ?? response;
      final newAlbum = Album.fromJson(albumData);
      // Refresh album list
      await fetchAll();
      return newAlbum;
    } catch (e) {
      print('Error creating album: $e');
      rethrow;
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await _apiService.deleteAlbum(albumId);
      // Refresh album list
      await fetchAll();
    } catch (e) {
      print('Error deleting album: $e');
      rethrow;
    }
  }

  Future<void> renameAlbum(String albumId, String newName) async {
    try {
      await _apiService.renameAlbum(albumId, newName);
      // Refresh album list
      await fetchAll();
    } catch (e) {
      print('Error renaming album: $e');
      rethrow;
    }
  }

  Future<List<Media>> getAlbumMedia(String albumId) async {
    try {
      return await _apiService.getAlbumMedia(albumId);
    } catch (e) {
      print('Error fetching album media: $e');
      rethrow;
    }
  }
}
