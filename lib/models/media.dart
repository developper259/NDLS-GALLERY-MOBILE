class Media {
  final String id;
  final String name;
  final String path;
  final String? thumb;
  final String type;
  final int size;
  final DateTime creation_date;
  final DateTime? upload_date;
  final bool isFavorite;
  final int? width;
  final int? height;
  final int? duration;

  Media({
    required this.id,
    required this.name,
    required this.path,
    this.thumb,
    required this.type,
    required this.size,
    required this.creation_date,
    this.upload_date,
    required this.isFavorite,
    this.width,
    this.height,
    this.duration,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les dates depuis différents formats
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();

      String dateStr = dateValue.toString();

      // Si c'est un objet Date JavaScript, il peut avoir la forme "2024-12-14T..."
      if (dateStr.contains('T') && dateStr.contains('-')) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          // Continuer avec les autres méthodes
        }
      }

      // Si c'est un timestamp (nombre)
      if (dateStr.isNotEmpty &&
          !dateStr.contains('-') &&
          !dateStr.contains(' ')) {
        try {
          final timestamp = int.tryParse(dateStr);
          if (timestamp != null) {
            // Vérifier si c'est en secondes ou millisecondes
            if (timestamp > 1000000000000) {
              // Probablement en millisecondes
              return DateTime.fromMillisecondsSinceEpoch(timestamp);
            } else {
              // Probablement en secondes
              return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            }
          }
        } catch (e) {
          // Continuer avec les autres méthodes
        }
      }

      // Essayer d'autres formats courants
      try {
        // Format JavaScript Date toString
        if (dateStr.contains('GMT') || dateStr.contains('UTC')) {
          // Essayer de parser manuellement les dates JavaScript
          final regex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
          final match = regex.firstMatch(dateStr);
          if (match != null) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        }
      } catch (e) {
        // Continuer avec le fallback
      }

      // En dernier recours, retourner la date actuelle
      return DateTime.now();
    }

    return Media(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      thumb: json['thumb']?.toString(),
      type: json['type']?.toString() ?? '',
      size: int.tryParse(json['size'].toString()) ?? 0,
      creation_date: parseDate(json['creation_date']),
      upload_date: json['upload_date'] != null
          ? parseDate(json['upload_date'])
          : null,
      isFavorite: json['favorite'] is bool
          ? json['favorite']
          : json['favorite']?.toString().toLowerCase() == 'true',
      width: json['width'] != null
          ? int.tryParse(json['width'].toString())
          : null,
      height: json['height'] != null
          ? int.tryParse(json['height'].toString())
          : null,
      duration: json['duration'] != null
          ? int.tryParse(json['duration'].toString())
          : null,
    );
  }
}
