import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_item.dart';
import 'postcard_image.dart';

/// A romantic vintage postcard card representing a couple memory.
///
/// Features:
/// - Polaroid/postcard white margin frame with paper texture feel.
/// - Organic subtle random rotation (-1.5° to +1.5°) for scrapbook feel.
/// - Top-right vintage airmail postage stamp & postmark cancellation badge.
/// - High-performance caching with memory constraints [CachedNetworkImage].
/// - Shimmer placeholder and graceful error fallback.
/// - Video indicator badge if [item.isVideo] is true.
/// - Romantic editorial title, location pill, and date stamp.
/// - Interactive favorite heart toggle.
class PostcardCard extends StatefulWidget {
  final GalleryItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const PostcardCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<PostcardCard> createState() => _PostcardCardState();
}

class _PostcardCardState extends State<PostcardCard> {
  late final double _rotationAngle;

  @override
  void initState() {
    super.initState();
    // Organic gentle tilt angle between -0.02 and +0.02 radians (~ -1.2° to +1.2°)
    final pseudoRandomSeed = (widget.index * 13) % 9;
    _rotationAngle = (pseudoRandomSeed - 4) * 0.005;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasCustomTitle = item.title.isNotEmpty &&
        item.title.toLowerCase() != 'our memory';

    return Transform.rotate(
      angle: _rotationAngle,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Photo Frame with Postage Stamp Badge
              Stack(
                children: [
                  // Photo / Video with PostcardImage
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 1.05,
                      child: PostcardImage(
                        item: item,
                        index: widget.index,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Top-Right Vintage Airmail Stamp
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.dustyRose.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 9,
                            color: AppColors.burgundy,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'PUVI',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.espresso,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Video Indicator Badge
                  if (item.isVideo)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'CLIP',
                              style: AppTypography.captionSmall.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // 2. Postcard Metadata & Handwriting Bottom Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title / Caption
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: hasCustomTitle ? 13.5 : 12.5,
                              fontWeight: hasCustomTitle
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontStyle: hasCustomTitle
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: AppColors.espresso,
                            ),
                          ),
                        ),
                        // Interactive Favorite Button
                        GestureDetector(
                          onTap: widget.onFavoriteToggle,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              item.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 17,
                              color: item.isFavorite
                                  ? AppColors.burgundy
                                  : AppColors.taupe.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Date Stamp & Location Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Postmark Date Stamp
                        Text(
                          item.formattedDate,
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 10.5,
                            color: AppColors.taupe,
                            letterSpacing: 0.2,
                          ),
                        ),

                        // Location or Tag
                        if (item.location != null &&
                            item.location!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blushSand,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 10,
                                  color: AppColors.burgundy,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  item.location!,
                                  style: AppTypography.captionSmall.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.burgundy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
