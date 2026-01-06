import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/album.dart';
import '../app_config.dart';
import '../views/album_view_screen.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';

class AlbumGrid extends StatefulWidget {
  final List<Album> albums;

  const AlbumGrid({super.key, required this.albums});

  @override
  State<AlbumGrid> createState() => _AlbumGridState();
}

class _AlbumGridState extends State<AlbumGrid> {
  bool _isOperationInProgress = false;

  void _showAlbumContextMenu(BuildContext context, Album album) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Renommer'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showRenameDialog(context, album);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Supprimer'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showDeleteConfirmation(context, album);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Album album) {
    if (_isOperationInProgress) return;

    final TextEditingController _renameController = TextEditingController(
      text: album.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer l\'album'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
            hintText: 'Entrez le nouveau nom de l\'album',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_renameController.text.isNotEmpty &&
                  _renameController.text != album.name &&
                  !_isOperationInProgress) {
                Navigator.of(context).pop();
                setState(() => _isOperationInProgress = true);

                try {
                  final mediaProvider = Provider.of<MediaProvider>(
                    context,
                    listen: false,
                  );
                  await mediaProvider.renameAlbum(
                    album.id,
                    _renameController.text,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Album renommé avec succès'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isOperationInProgress = false);
                  }
                }
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Album album) {
    if (_isOperationInProgress) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'album'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'album "${album.name}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_isOperationInProgress) return;

              Navigator.of(context).pop();
              setState(() => _isOperationInProgress = true);

              try {
                final mediaProvider = Provider.of<MediaProvider>(
                  context,
                  listen: false,
                );
                await mediaProvider.deleteAlbum(album.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Album supprimé avec succès')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              } finally {
                if (mounted) {
                  setState(() => _isOperationInProgress = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.0,
      ),
      itemCount: widget.albums.length,
      itemBuilder: (context, index) {
        final album = widget.albums[index];
        // Prioritize thumbnail over coverUrl
        final thumbnailUrl = album.thumbnail != null
            ? AppConfig.baseUrl + album.thumbnail!
            : album.coverUrl != null
            ? AppConfig.baseUrl + (album.coverUrl ?? '')
            : null;

        return InkWell(
          onLongPress: () {
            _showAlbumContextMenu(context, album);
          },
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AlbumViewScreen(album: album),
              ),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: GridTile(
              footer: GridTileBar(
                backgroundColor: Colors.black45,
                title: Text(album.name, style: const TextStyle(fontSize: 16)),
                subtitle: Text('${album.mediaCount} items'),
              ),
              child: thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) {
                        return const Icon(Icons.broken_image, size: 48);
                      },
                    )
                  : const Icon(Icons.photo_album, size: 48, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
