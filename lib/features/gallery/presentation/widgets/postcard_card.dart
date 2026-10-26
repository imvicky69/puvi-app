import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_item.dart';
import 'postcard_image.dart';

/// Clean, photo-centric gallery card representing a couple memory.
///
/// Features:
/// - True aspect-ratio preservation without aggressive cropping or distortion.
/// - Minimalist aesthetic: pure photo, subtle date stamp, and optional custom note.
/// - No clutter: eliminated repetitive "Our memory" titles, like buttons, and postage stamps.
/// - Video indicator badge if [item.isVideo] is true.
/// - Tactile tap feedback to launch full-screen interactive viewer.
class PostcardCard extends StatelessWidget {
  final GalleryItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const PostcardCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Preserve 100% natural aspect ratios (from tall 9:16 portrait to 16:9 landscape)
    final naturalAspectRatio = item.aspectRatio.clamp(0.48, 2.0);

    // Only display short note if it's a genuine custom memory note (not default placeholder)
    final hasCustomNote =
        item.title.trim().isNotEmpty &&
        item.title.trim().toLowerCase() != 'our memory';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.espresso.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Photo / Video at its true aspect ratio
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: naturalAspectRatio,
                  child: PostcardImage(
                    item: item,
                    index: index,
                    fit: BoxFit.cover,
                  ),
                ),

                // Video Indicator Pill
                if (item.isVideo)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.7,
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
                            'VIDEO',
                            style: AppTypography.captionSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Minimalist caption area: Date and optional short note ONLY
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Optional custom short note (if written by user)
                  if (hasCustomNote) ...[
                    Text(
                      item.title.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],

                  // Subtle Date Stamp
                  Text(
                    item.formattedDate,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 10.5,
                      color: AppColors.taupe,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
