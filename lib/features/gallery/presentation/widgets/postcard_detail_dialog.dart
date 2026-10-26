import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_item.dart';
import '../../data/media_download_service.dart';
import 'edit_metadata_dialog.dart';
import 'postcard_image.dart';
import 'postcard_video_player.dart';

/// Clean, borderless modal viewer for postcards with Download & Edit features.
class PostcardDetailDialog extends StatefulWidget {
  final GalleryItem item;
  final VoidCallback onFavoriteToggle;
  final ValueChanged<GalleryItem>? onUpdate;

  const PostcardDetailDialog({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
    this.onUpdate,
  });

  @override
  State<PostcardDetailDialog> createState() => _PostcardDetailDialogState();
}

class _PostcardDetailDialogState extends State<PostcardDetailDialog> {
  late GalleryItem _item;
  late bool _isFavorite;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _isFavorite = widget.item.isFavorite;
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);

    try {
      final result = await MediaDownloadService.downloadToGallery(_item);
      if (!mounted) return;

      if (result.status == DownloadResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.paper,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved to phone gallery in "Puvi" album 💕',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.paper,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'View',
              textColor: AppColors.dustyRose,
              onPressed: MediaDownloadService.openPhoneGallery,
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.espresso,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result.status == DownloadResultStatus.permissionDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Permission needed to save to gallery 💕',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.paper),
            ),
            backgroundColor: AppColors.burgundy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Failed to save to gallery.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.paper),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _openEditDialog() {
    showDialog(
      context: context,
      builder: (context) => EditMetadataDialog(
        item: _item,
        onSave: (updated) {
          setState(() {
            _item = updated;
          });
          widget.onUpdate?.call(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        side: BorderSide.none,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Media: PostcardVideoPlayer for clips, PostcardImage for photos
                  if (_item.isVideo)
                    PostcardVideoPlayer(
                      videoUrl: _item.mediaUrl.isNotEmpty
                          ? _item.mediaUrl
                          : _item.imageUrl,
                      fallbackAspectRatio: _item.aspectRatio,
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: _item.aspectRatio.clamp(0.65, 1.4),
                        child: PostcardImage(
                          item: _item,
                          index: 0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 2. Metadata Section: Title, Location, Date, and Favorite Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _item.title,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.espresso,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _item.formattedDate,
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.taupe,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (_item.location != null &&
                                      _item.location!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
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
                                            _item.location!,
                                            style: AppTypography.captionSmall
                                                .copyWith(
                                                  fontSize: 10,
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

                        // Favorite Heart
                        IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _isFavorite
                                ? AppColors.burgundy
                                : AppColors.taupe,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() => _isFavorite = !_isFavorite);
                            widget.onFavoriteToggle();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Action Buttons: Download, Edit & Close
                  Row(
                    children: [
                      // Download Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _isDownloading ? null : _handleDownload,
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.paper,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            _isDownloading ? 'Saving...' : 'Download',
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Edit Metadata Button
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _openEditDialog,
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('Edit'),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Close Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
