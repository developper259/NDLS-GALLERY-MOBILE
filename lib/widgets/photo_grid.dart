import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/media.dart';
import '../app_config.dart';
import '../views/photo_view_screen.dart';
import '../services/media_provider.dart';

class PhotoGrid extends StatelessWidget {
  final List<Media> media;

  const PhotoGrid({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final groupedMedia = _groupMediaByMonth(media);
    final sortedKeys = groupedMedia.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<MediaProvider>(context, listen: false).fetchAll();
      },
      child: CustomScrollView(
        slivers: sortedKeys
            .map((key) {
              final monthlyMedia = groupedMedia[key]!;
              return [
                SliverToBoxAdapter(
                  child: _buildGroupSeparator(monthlyMedia.first),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 1.0,
                    mainAxisSpacing: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildGridItem(context, monthlyMedia[index]),
                    childCount: monthlyMedia.length,
                  ),
                ),
              ];
            })
            .expand((element) => element)
            .toList(),
      ),
    );
  }

  String _getGroupKey(Media media) {
    return DateFormat('yyyy-MM').format(media.creation_date);
  }

  Map<String, List<Media>> _groupMediaByMonth(List<Media> media) {
    final Map<String, List<Media>> grouped = {};
    for (var m in media) {
      final key = _getGroupKey(m);
      if (grouped[key] == null) {
        grouped[key] = [];
      }
      grouped[key]!.add(m);
    }
    return grouped;
  }

  Widget _buildGroupSeparator(Media media) {
    final currentYear = DateTime.now().year;
    final year = media.creation_date.year;
    final month = DateFormat.MMMM('fr_FR').format(media.creation_date);
    final monthKey = year == currentYear
        ? '${month[0].toUpperCase()}${month.substring(1)}'
        : '${month[0].toUpperCase()}${month.substring(1)} $year';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: Text(
        monthKey,
        style: const TextStyle(
          fontSize: 22,
          color: Colors.grey,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, Media item) {
    final thumbUrl = item.thumb != null
        ? AppConfig.baseUrl + item.thumb!
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, _, __) {
              return PhotoViewScreen(media: item, allMedia: media);
            },
          ),
        );
      },
      child: Container(
        color: Colors.grey[200],
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbUrl != null)
                CachedNetworkImage(
                  imageUrl: thumbUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  memCacheHeight: 400,
                  cacheKey: thumbUrl,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, color: Colors.grey),
                )
              else
                const Icon(Icons.photo, color: Colors.grey),
              if (item.isFavorite)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              if (item.type == 'video')
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 12,
                        ),
                        if (item.duration != null)
                          Text(
                            _formatDuration(item.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
