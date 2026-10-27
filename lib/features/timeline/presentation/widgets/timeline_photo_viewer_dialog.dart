import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Full-screen, true uncropped photo viewer for timeline milestones.
///
/// Features:
/// - True actual-size rendering with [BoxFit.contain] (zero cropping).
/// - Pinch-to-zoom and pan up to 8x via [InteractiveViewer].
/// - Instant 1:1 Actual Size / Fit Screen toggle button.
/// - Double-tap to instantly zoom into tapped position.
/// - Tap to toggle caption & control bars.
/// - Immersive AMOLED true black edge-to-edge backdrop.
class TimelinePhotoViewerDialog extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String? location;
  final String date;

  const TimelinePhotoViewerDialog({
    super.key,
    required this.imageUrl,
    required this.title,
    this.location,
    required this.date,
  });

  static void show(
    BuildContext context, {
    required String imageUrl,
    required String title,
    String? location,
    required String date,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.96),
        pageBuilder: (context, animation, secondaryAnimation) =>
            TimelinePhotoViewerDialog(
              imageUrl: imageUrl,
              title: title,
              location: location,
              date: date,
            ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<TimelinePhotoViewerDialog> createState() =>
      _TimelinePhotoViewerDialogState();
}

class _TimelinePhotoViewerDialogState extends State<TimelinePhotoViewerDialog>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late TapDownDetails _doubleTapDetails;
  bool _showControls = true;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final isZoomedNow = _transformController.value != Matrix4.identity();
    if (isZoomedNow != _isZoomed) {
      setState(() {
        _isZoomed = isZoomedNow;
      });
    }
  }

  void _toggleZoom() {
    if (_isZoomed) {
      _transformController.value = Matrix4.identity();
    } else {
      final size = MediaQuery.of(context).size;
      final center = Offset(size.width / 2, size.height / 2);
      _transformController.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0)
        ..setTranslationRaw(-center.dx * 1.5, -center.dy * 1.5, 0.0);
    }
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails.localPosition;
      _transformController.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0)
        ..setTranslationRaw(-position.dx * 1.5, -position.dy * 1.5, 0.0);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocal =
        !widget.imageUrl.startsWith('http://') &&
        !widget.imageUrl.startsWith('https://');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Center Edge-to-Edge Zoomable Image (True Uncropped Actual Proportions)
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: (d) => _doubleTapDetails = d,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformController,
              clipBehavior: Clip.none,
              minScale: 0.5,
              maxScale: 8.0,
              child: SizedBox.expand(
                child: isLocal
                    ? (File(widget.imageUrl).existsSync()
                          ? Image.file(
                              File(widget.imageUrl),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildErrorView(),
                            )
                          : _buildErrorView())
                    : CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.dustyRose,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildErrorView(),
                      ),
              ),
            ),
          ),

          // 2. Top Control Bar (Animated position)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.black.withValues(alpha: 0.55),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Spacer(),

                    // Zoom 1:1 Toggle button
                    InkWell(
                      onTap: _toggleZoom,
                      borderRadius: AppRadius.borderPill,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: AppRadius.borderPill,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isZoomed
                                  ? Icons.zoom_out_map_rounded
                                  : Icons.zoom_in_rounded,
                              size: 14,
                              color: AppColors.dustyRose,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isZoomed ? 'Fit Screen' : 'Actual Size (1:1)',
                              style: AppTypography.captionSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.horizontalXs,

                    // Date Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: AppRadius.borderPill,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.dustyRose,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.date,
                            style: AppTypography.captionSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Caption Card (Animated position)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -150,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: AppRadius.borderCard,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.location != null &&
                          widget.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: AppColors.dustyRose,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.location!,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Actual Proportions • Double tap, pinch to zoom, or tap to hide info',
                        style: AppTypography.captionSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                        ),
                      ),
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

  Widget _buildErrorView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: AppColors.dustyRose,
            size: 48,
          ),
          SizedBox(height: 8),
          Text('Unable to load photo', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
