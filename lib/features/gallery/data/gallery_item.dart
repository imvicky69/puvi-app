/// Domain model representing a single memory in the Puvi Gallery.
class GalleryItem {
  final String id;
  final String imageUrl;
  final String mediaUrl;
  final String thumbnailUrl;
  final String storagePath;
  final String title;
  final String type; // 'image' | 'video'
  final bool isVideo;
  final DateTime createdAt;
  final DateTime takenAt;
  final String coupleId;
  final bool isFavorite;
  final String album;
  final String? location;
  final String? fileExtension;
  final double aspectRatio;

  const GalleryItem({
    required this.id,
    required this.imageUrl,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.storagePath,
    required this.title,
    required this.type,
    required this.isVideo,
    required this.createdAt,
    required this.takenAt,
    this.coupleId = 'puvi_couple',
    this.isFavorite = false,
    this.album = 'All',
    this.location,
    this.fileExtension,
    this.aspectRatio = 0.75,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.toLowerCase() ?? 'image';
    final isVid = json['isVideo'] == true ||
        rawType == 'video' ||
        (json['storagePath'] as String? ?? '').endsWith('.mp4') ||
        (json['storagePath'] as String? ?? '').endsWith('.mov');

    final rawCreatedAt = json['createdAt'];
    DateTime createdDate = DateTime.now();
    if (rawCreatedAt is String) {
      createdDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    final rawTakenAt = json['takenAt'];
    DateTime takenDate = createdDate;
    if (rawTakenAt is String) {
      takenDate = DateTime.tryParse(rawTakenAt) ?? createdDate;
    }

    final imgUrl = json['imageUrl'] as String? ?? '';
    final medUrl = json['mediaUrl'] as String? ?? imgUrl;
    final thumbUrl = json['thumbnailUrl'] as String? ?? imgUrl;

    return GalleryItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      imageUrl: imgUrl,
      mediaUrl: medUrl,
      thumbnailUrl: thumbUrl,
      storagePath: json['storagePath'] as String? ?? '',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Our memory',
      type: isVid ? 'video' : 'image',
      isVideo: isVid,
      createdAt: createdDate,
      takenAt: takenDate,
      coupleId: json['coupleId'] as String? ?? 'puvi_couple',
      isFavorite: json['isFavorite'] == true,
      album: json['album'] as String? ?? 'All',
      location: json['location'] as String?,
      fileExtension: json['fileExtension'] as String?,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? (isVid ? 0.75 : 0.8),
    );
  }

  GalleryItem copyWith({
    bool? isFavorite,
    String? title,
    String? location,
    DateTime? takenAt,
    double? aspectRatio,
  }) {
    return GalleryItem(
      id: id,
      imageUrl: imageUrl,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      storagePath: storagePath,
      title: title ?? this.title,
      type: type,
      isVideo: isVideo,
      createdAt: createdAt,
      takenAt: takenAt ?? this.takenAt,
      coupleId: coupleId,
      isFavorite: isFavorite ?? this.isFavorite,
      album: album,
      location: location ?? this.location,
      fileExtension: fileExtension,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'takenAt': takenAt.toIso8601String(),
      'isFavorite': isFavorite,
      'aspectRatio': aspectRatio,
    };
  }

  /// Formatted date string for the postcard stamp (e.g. "May 25, 2026")
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[takenAt.month - 1];
    return '$m ${takenAt.day}, ${takenAt.year}';
  }
}
