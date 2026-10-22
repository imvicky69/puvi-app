import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/gallery_item.dart';

/// Resilient, high-performance image and video viewer for gallery postcards.
///
/// Features:
/// - Handles photos with engine-level downsampling cache ([cacheWidth], [cacheHeight])
///   using Flutter's built-in ImageCache (zero native plugin crash risks).
/// - Gracefully renders video items (.mp4/.mov) with a cinematic video card
///   and frosted play button.
/// - Built-in smooth progress indicator and offline asset error fallback.
class PostcardImage extends StatelessWidget {
  final GalleryItem item;
  final int index;
  final BoxFit fit;

  const PostcardImage({
    super.key,
    required this.item,
    required this.index,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) {
      return _buildVideoPreview(context);
    }
    return _buildPhotoImage(context);
  }

  Widget _buildPhotoImage(BuildContext context) {
    final url = item.imageUrl.isNotEmpty ? item.imageUrl : item.mediaUrl;
    final fallbackAsset = (index % 2 == 0)
        ? 'assets/puvi-1.jpeg'
        : 'assets/puvi-2.jpeg';

    if (url.isEmpty) {
      return Image.asset(fallbackAsset, fit: fit);
    }

    return Image.network(
      url,
      fit: fit,
      cacheWidth: 600,
      cacheHeight: 800,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.blushSand.withValues(alpha: 0.5),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.dustyRose.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(fallbackAsset, fit: fit);
      },
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final fallbackAsset = (index % 2 == 0)
        ? 'assets/puvi-1.jpeg'
        : 'assets/puvi-2.jpeg';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background photo preview with dark tint
        Image.asset(
          fallbackAsset,
          fit: fit,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                AppColors.burgundy.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.75),
              ],
            ),
          ),
        ),

        // Glowing center play button
        Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.burgundy,
              size: 26,
            ),
          ),
        ),

        // Bottom Video Label
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Video Memory',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
