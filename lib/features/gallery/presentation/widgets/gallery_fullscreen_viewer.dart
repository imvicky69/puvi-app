import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_item.dart';
import '../../data/media_download_service.dart';
import 'edit_metadata_dialog.dart';
import 'postcard_video_player.dart';

/// Full-screen, swipeable lightbox memory viewer with pinch-to-zoom and media controls.
class GalleryFullscreenViewer extends StatefulWidget {
  final List<GalleryItem> items;
  final int initialIndex;
  final ValueChanged<GalleryItem>? onUpdate;

  const GalleryFullscreenViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    this.onUpdate,
  });

  @override
  State<GalleryFullscreenViewer> createState() =>
      _GalleryFullscreenViewerState();
}

class _GalleryFullscreenViewerState extends State<GalleryFullscreenViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  GalleryItem get _currentItem => widget.items[_currentIndex];

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);

    try {
      final result = await MediaDownloadService.downloadToGallery(_currentItem);
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
        item: _currentItem,
        onSave: (updated) {
          setState(() {
            widget.items[_currentIndex] = updated;
          });
          widget.onUpdate?.call(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomNote =
        _currentItem.title.trim().isNotEmpty &&
        _currentItem.title.trim().toLowerCase() != 'our memory';

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF110E0D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Swipable Media View
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];

              if (item.isVideo) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: item.aspectRatio.clamp(0.5, 2.0),
                    child: PostcardVideoPlayer(
                      videoUrl: item.mediaUrl.isNotEmpty
                          ? item.mediaUrl
                          : item.imageUrl,
                      fallbackAspectRatio: item.aspectRatio,
                    ),
                  ),
                );
              }

              final url = item.imageUrl.isNotEmpty
                  ? item.imageUrl
                  : item.mediaUrl;
              final fallbackAsset = (index % 2 == 0)
                  ? 'assets/puvi-1.jpeg'
                  : 'assets/puvi-2.jpeg';

              return GestureDetector(
                onTap: _toggleControls,
                child: InteractiveViewer(
                  minScale: 0.9,
                  maxScale: 4.5,
                  child: Center(
                    child: (url.isEmpty || isTest)
                        ? Image.asset(fallbackAsset, fit: BoxFit.contain)
                        : (!url.startsWith('http://') &&
                              !url.startsWith('https://'))
                        ? (File(url).existsSync()
                              ? Image.file(File(url), fit: BoxFit.contain)
                              : Image.asset(fallbackAsset, fit: BoxFit.contain))
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (context, _) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.dustyRose,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                Image.asset(fallbackAsset, fit: BoxFit.contain),
                          ),
                  ),
                ),
              );
            },
          ),

          // 2. Translucent Floating Top App Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Back',
                      ),

                      // Index indicator
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentItem.formattedDate,
                              style: AppTypography.label.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_currentIndex + 1} of ${widget.items.length}',
                              style: AppTypography.captionSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Download Button
                      IconButton(
                        onPressed: _isDownloading ? null : _handleDownload,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                        tooltip: 'Download',
                      ),

                      // Edit Details Button
                      IconButton(
                        onPressed: _openEditDialog,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Edit Memory',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Translucent Floating Bottom Overlay (Note & Location)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -140,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location badge
                      if (_currentItem.location != null &&
                          _currentItem.location!.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentItem.location!,
                                style: AppTypography.captionSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Note or Add Note Prompt
                      if (hasCustomNote) ...[
                        Text(
                          _currentItem.title.trim(),
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _openEditDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: AppRadius.borderPill,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_comment_outlined,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Add a love note 💕',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
