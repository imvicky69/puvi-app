import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_item.dart';

/// Full-screen interactive Postcard modal viewer with 3D flip animation.
class PostcardDetailDialog extends StatefulWidget {
  final GalleryItem item;
  final VoidCallback onFavoriteToggle;

  const PostcardDetailDialog({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
  });

  @override
  State<PostcardDetailDialog> createState() => _PostcardDetailDialogState();
}

class _PostcardDetailDialogState extends State<PostcardDetailDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _animation;
  bool _showBack = false;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  void _flipCard() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * pi;
              final isUnder = (angle >= pi / 2);

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 3D perspective
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isUnder
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: _buildBack(item),
                      )
                    : _buildFront(item),
              );
            },
          ),
        ),
      ),
    );
  }

  // Front of Postcard: Photo & Postmark
  Widget _buildFront(GalleryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Video container
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.imageUrl.isNotEmpty
                        ? item.imageUrl
                        : item.mediaUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    memCacheHeight: 800,
                    placeholder: (context, url) => Container(
                      color: AppColors.blushSand,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.blushSand,
                      child: Image.asset('assets/puvi-1.jpeg', fit: BoxFit.cover),
                    ),
                  ),

                  // Video overlay indicator
                  if (item.isVideo)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Caption & Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Captured on ${item.formattedDate}',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.taupe,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorite
                        ? AppColors.burgundy
                        : AppColors.taupe,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() => _isFavorite = !_isFavorite);
                    widget.onFavoriteToggle();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Action Buttons: Flip Card & Close
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _flipCard,
                  icon: const Icon(Icons.flip_rounded, size: 16),
                  label: const Text('Read Postcard'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Back of Postcard: Handwritten Note, Stamp, Lines
  Widget _buildBack(GalleryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Postmark & Stamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAR AVION • POST CARD',
                    style: AppTypography.captionSmall.copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.espresso,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'VICKY & PUJA • PUVI',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.taupe,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              // Vintage Stamp Box
              Container(
                width: 44,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.dustyRose, width: 1.2),
                  color: AppColors.blushSand,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: AppColors.burgundy,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2026',
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.espresso,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 28),

          // Handwritten Note Area
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppColors.espresso,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"Every second spent with you is a memory worth treasuring forever. Our private sanctuary grows more beautiful each day."',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: AppColors.espresso.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppColors.taupe,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.formattedDate,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.taupe,
                        ),
                      ),
                    ],
                  ),
                  if (item.fileExtension != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          size: 13,
                          color: AppColors.taupe,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Type: ${item.type.toUpperCase()} (${item.fileExtension})',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.taupe,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Return button
          ElevatedButton.icon(
            onPressed: _flipCard,
            icon: const Icon(Icons.flip_rounded, size: 16),
            label: const Text('Back to Photo'),
          ),
        ],
      ),
    );
  }
}
