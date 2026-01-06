import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media.dart';
import '../models/album.dart';
import '../app_config.dart';
import 'photo_view_screen.dart';
import 'package:provider/provider.dart';
import '../services/media_provider.dart';

class AlbumViewScreen extends StatefulWidget {
  final Album album;

  const AlbumViewScreen({super.key, required this.album});

  @override
  State<AlbumViewScreen> createState() => _AlbumViewScreenState();
}

class _AlbumViewScreenState extends State<AlbumViewScreen> {
  late Future<List<Media>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _mediaFuture = _fetchAlbumMedia();
  }

  Future<List<Media>> _fetchAlbumMedia() async {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    return await mediaProvider.getAlbumMedia(widget.album.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Media>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No media in this album',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final mediaList = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(4.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaList[index];
              final imageUrl = AppConfig.baseUrl + media.path;
              final thumbUrl = media.thumb != null
                  ? AppConfig.baseUrl + media.thumb!
                  : null;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          PhotoViewScreen(media: media, allMedia: mediaList),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: media.type == 'video'
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: thumbUrl ?? imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                            const Positioned(
                              bottom: 4,
                              right: 4,
                              child: Icon(
                                Icons.play_circle_filled,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        )
                      : CachedNetworkImage(
                          imageUrl: thumbUrl ?? imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
