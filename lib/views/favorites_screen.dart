import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';
import '../widgets/photo_grid.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.favorites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.favorites.isEmpty) {
            return const Center(child: Text('No favorites found.'));
          }

          return PhotoGrid(media: provider.favorites);
        },
      ),
    );
  }
}
