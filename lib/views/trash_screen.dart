import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';
import '../widgets/photo_grid.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.trash.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.trash.isEmpty) {
            return const Center(child: Text('Trash is empty.'));
          }

          return PhotoGrid(media: provider.trash);
        },
      ),
    );
  }
}
