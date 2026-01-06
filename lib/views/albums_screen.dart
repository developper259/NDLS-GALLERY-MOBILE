import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';
import '../widgets/album_grid.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  Future<void> _refreshAlbums(BuildContext context) async {
    await Provider.of<MediaProvider>(context, listen: false).fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAlbums(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAlbums(context),
        child: Consumer<MediaProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.albums.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.albums.isEmpty) {
              return const Center(child: Text('No albums found.'));
            }

            return AlbumGrid(albums: provider.albums);
          },
        ),
      ),
    );
  }
}
