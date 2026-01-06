class Album {
  final String id;
  final String name;
  final String? description;
  final int mediaCount;
  final String? coverUrl;
  final String? thumbnail;

  Album({
    required this.id,
    required this.name,
    this.description,
    required this.mediaCount,
    this.coverUrl,
    this.thumbnail,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      mediaCount: json['media_count'] ?? json['mediaCount'] ?? 0,
      coverUrl: json['cover_url'],
      thumbnail: json['thumbnail'] ?? json['media']?['thumbnail'],
    );
  }
}
