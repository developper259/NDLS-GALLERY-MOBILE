import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media.dart';
import '../app_config.dart';
import '../widgets/video_player_widget.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';
import 'album_view_screen.dart';

class PhotoViewScreen extends StatefulWidget {
  final Media media;
  final List<Media> allMedia;

  const PhotoViewScreen({
    super.key,
    required this.media,
    required this.allMedia,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;
  final PanelController _panelController = PanelController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allMedia.indexOf(widget.media);
    _pageController = PageController(initialPage: _currentIndex);
    _transformationController = TransformationController();
    _preloadImages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // Helper pour construire l'image avec chargement progressif
  Widget _buildImageWithQuality({required String imageUrl, String? thumbUrl}) {
    return FadeInImage(
      placeholder: CachedNetworkImageProvider(
        thumbUrl ?? imageUrl, // Utilise le thumbnail comme placeholder
        maxWidth: 400,
        maxHeight: 400,
      ),
      image: CachedNetworkImageProvider(
        imageUrl, // Image haute qualité
        maxWidth: 2048,
        maxHeight: 2048,
      ),
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      // Transition de fondu pour une apparition douce
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      // Assure que le placeholder ne saute pas
      placeholderFit: BoxFit.contain,
    );
  }

  void _preloadImages() {
    // Précharger les images adjacentes pour un swipe fluide
    final preloadRange = 1; // Réduire à 1 pour moins de latence
    final start = (_currentIndex - preloadRange).clamp(
      0,
      widget.allMedia.length - 1,
    );
    final end = (_currentIndex + preloadRange).clamp(
      0,
      widget.allMedia.length - 1,
    );

    // Précharger les images adjacentes de manière asynchrone
    for (int i = start; i <= end; i++) {
      if (i >= 0 && i < widget.allMedia.length && i != _currentIndex) {
        final media = widget.allMedia[i];
        final imageUrl = AppConfig.baseUrl + media.path;

        // Précharger l'image avec des paramètres optimisés
        CachedNetworkImage(
          imageUrl: imageUrl,
          memCacheWidth: 800, // Taille réduite pour chargement plus rapide
          memCacheHeight: 800,
          cacheKey: imageUrl,
        );
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Précharger les nouvelles images adjacentes
    _preloadImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          // Only detect swipes if the image is not zoomed
          if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
            if (details.delta.dy < -10) {
              // Swipe up
              _panelController.open();
            }
          }
        },
        child: SlidingUpPanel(
          panel: _buildPanel(),
          minHeight: 0,
          maxHeight: 350, // Increased height for more content
          backdropEnabled: true,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
          controller: _panelController,
          body: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.allMedia.length,
            itemBuilder: (context, index) {
              final media = widget.allMedia[index];
              final imageUrl = AppConfig.baseUrl + media.path;
              final thumbUrl = media.thumb != null
                  ? AppConfig.baseUrl + media.thumb!
                  : null;

              return Center(
                child: media.type == 'video'
                    ? VideoPlayerWidget(
                        videoUrl: imageUrl,
                        thumbnailUrl: thumbUrl,
                      )
                    : GestureDetector(
                        onTap: () {
                          // Reset zoom on tap
                          final transform = _transformationController.value;
                          final scale = transform.getMaxScaleOnAxis();
                          if (scale > 1.0) {
                            _transformationController.value =
                                Matrix4.identity();
                          } else {
                            // Optionally, you could toggle UI elements here
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 5.0,
                          boundaryMargin: EdgeInsets.zero,
                          onInteractionEnd: (details) {
                            // Snap back to 1.0x if scale is close to it
                            final transform = _transformationController.value;
                            final scale = transform.getMaxScaleOnAxis();
                            if (scale < 1.0) {
                              _transformationController.value =
                                  Matrix4.identity();
                            }
                          },
                          child: _buildImageWithQuality(
                            imageUrl: imageUrl,
                            thumbUrl: thumbUrl,
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: Colors.black.withOpacity(0.5),
        child: const Icon(Icons.close, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  Widget _buildPanel() {
    final media = widget.allMedia[_currentIndex];
    final creationDate = DateFormat('dd MMMM yyyy').format(media.creation_date);
    final fileSize = _formatSize(media.size);

    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(240, 40, 40, 40),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$creationDate • $fileSize',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (media.type == 'video' && media.duration != null)
                  Text(
                    'Duration: ${_formatDuration(media.duration!)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                if (media.type != 'video' &&
                    media.width != null &&
                    media.height != null)
                  Text(
                    'Dimensions: ${media.width}x${media.height}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const Spacer(),
          _buildActionButtons(),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  void _shareMedia() {
    final media = widget.allMedia[_currentIndex];
    final url = AppConfig.baseUrl + media.path;
    Share.share('Check out this media: $url');
  }

  void _deleteMedia() {
    final media = widget.allMedia[_currentIndex];
    Provider.of<MediaProvider>(context, listen: false).deleteMedia(media);
    Navigator.of(context).pop(); // Close the photo view
  }

  void _showAlbumDialog() {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final albums = mediaProvider.albums;
    final media = widget.allMedia[_currentIndex];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Album'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showCreateAlbumDialog(media);
                  },
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Create New Album'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: album.coverUrl != null
                              ? NetworkImage(
                                  AppConfig.baseUrl + album.coverUrl!,
                                )
                              : null,
                          child: album.coverUrl == null
                              ? const Icon(Icons.photo_library)
                              : null,
                        ),
                        title: Text(album.name),
                        subtitle: Text('${album.mediaCount} items'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AlbumViewScreen(album: album),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateAlbumDialog(Media media) {
    final TextEditingController _albumNameController = TextEditingController();
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Album'),
          content: TextField(
            controller: _albumNameController,
            decoration: const InputDecoration(
              labelText: 'Album Name',
              hintText: 'Enter album name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_albumNameController.text.isNotEmpty) {
                  try {
                    // Assuming there's a method to create an album
                    // For now, we'll simulate it and add to a default album
                    // You'll need to implement createAlbum in MediaProvider
                    final newAlbum = await mediaProvider.createAlbum(
                      _albumNameController.text,
                    );
                    mediaProvider.addMediaToAlbum(newAlbum.id, media.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to new album: ${newAlbum.name}'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create album: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        final media = widget.allMedia[_currentIndex];
        final isFavorite = mediaProvider.favorites.any(
          (fav) => fav.id == media.id,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconButton(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              'Favorite',
              () {
                // Optimistically update the UI
                final updatedMedia = Media(
                  id: media.id,
                  name: media.name,
                  path: media.path,
                  thumb: media.thumb,
                  type: media.type,
                  size: media.size,
                  creation_date: media.creation_date,
                  upload_date: media.upload_date,
                  isFavorite: !isFavorite,
                  width: media.width,
                  height: media.height,
                  duration: media.duration,
                );
                widget.allMedia[_currentIndex] = updatedMedia;
                setState(() {});

                // Then call the provider to sync with the backend
                mediaProvider.toggleFavorite(media);
              },
            ),
            _buildIconButton(Icons.share, 'Share', _shareMedia),
            _buildIconButton(
              Icons.add_to_photos_outlined,
              'Add to Album',
              _showAlbumDialog,
            ),
            _buildIconButton(Icons.delete_outline, 'Delete', _deleteMedia),
          ],
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$secs';
    }
    return '$minutes:$secs';
  }
}
