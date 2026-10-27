/// Domain model representing a romantic milestone in Puja & Vicky's timeline.
class TimelineItem {
  final String id;
  final String title;
  final DateTime date;
  final String note;
  final String? location;
  final String? imageUrl;
  final String category;
  final String authorName;
  final String coupleId;
  final Map<String, double>? coordinates;
  final bool isFavorite;
  final DateTime createdAt;

  const TimelineItem({
    required this.id,
    required this.title,
    required this.date,
    this.note = '',
    this.location,
    this.imageUrl,
    this.category = 'Milestones',
    this.authorName = 'Puja & Vicky',
    this.coupleId = 'puvi_couple',
    this.coordinates,
    this.isFavorite = false,
    required this.createdAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get hasLocation => location != null && location!.trim().isNotEmpty;
  bool get hasNote => note.trim().isNotEmpty;

  /// Returns clean formatted date, e.g. "April 11, 2026"
  String get formattedDate {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final m = months[date.month - 1];
    return '$m ${date.day}, ${date.year}';
  }

  /// Returns vintage postal stamp date, e.g. "11 APR 2026"
  String get postalStampDate {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final m = months[date.month - 1];
    final dayStr = date.day < 10 ? '0${date.day}' : '${date.day}';
    return '$dayStr $m ${date.year}';
  }

  /// Returns the year string, e.g. "2026"
  String get yearString => '${date.year}';

  /// Calculates day count offset from relationship anniversary (April 11, 2026)
  int daysOffsetFrom(DateTime anchor) {
    return date.difference(anchor).inDays;
  }

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    // 1. Parse date
    DateTime parsedDate = DateTime.now();
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    }

    // 2. Parse createdAt
    DateTime createdDate = parsedDate;
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt is String) {
      createdDate = DateTime.tryParse(rawCreatedAt) ?? parsedDate;
    } else if (rawCreatedAt is DateTime) {
      createdDate = rawCreatedAt;
    }

    // 3. Parse coordinates
    Map<String, double>? parsedCoords;
    if (json['coordinates'] is Map) {
      final map = json['coordinates'] as Map;
      final lat = (map['lat'] as num?)?.toDouble();
      final lng = (map['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        parsedCoords = {'lat': lat, 'lng': lng};
      }
    }

    // 4. Clean strings
    final rawImg = json['imageUrl'] as String?;
    final cleanedImg = (rawImg != null && rawImg.trim().isNotEmpty)
        ? rawImg.trim()
        : null;

    final rawLoc = json['location'] as String?;
    final cleanedLoc = (rawLoc != null && rawLoc.trim().isNotEmpty)
        ? rawLoc.trim()
        : null;

    return TimelineItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: (json['title'] as String?)?.trim() ?? 'Untitled Memory',
      date: parsedDate,
      note: (json['note'] as String?)?.trim() ?? '',
      location: cleanedLoc,
      imageUrl: cleanedImg,
      category: (json['category'] as String?)?.trim() ?? 'Milestones',
      authorName: (json['authorName'] as String?)?.trim() ?? 'Puja & Vicky',
      coupleId: json['coupleId'] as String? ?? 'puvi_couple',
      coordinates: parsedCoords,
      isFavorite: json['isFavorite'] == true,
      createdAt: createdDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'date': date.toIso8601String().split('T').first,
      'note': note,
      'location': location,
      'imageUrl': imageUrl,
      'category': category,
      'authorName': authorName,
      'coupleId': coupleId,
      'coordinates': coordinates,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TimelineItem copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? note,
    String? location,
    String? imageUrl,
    String? category,
    String? authorName,
    String? coupleId,
    Map<String, double>? coordinates,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return TimelineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      note: note ?? this.note,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      authorName: authorName ?? this.authorName,
      coupleId: coupleId ?? this.coupleId,
      coordinates: coordinates ?? this.coordinates,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
