import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/timeline_item.dart';
import 'timeline_photo_viewer_dialog.dart';

/// Fullscreen intimate Love Letter modal reading sheet for a single milestone.
class MilestoneDetailSheet extends StatelessWidget {
  final TimelineItem item;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MilestoneDetailSheet({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required TimelineItem item,
    required VoidCallback onFavoriteToggle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MilestoneDetailSheet(
        item: item,
        onFavoriteToggle: onFavoriteToggle,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.90),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: AppRadius.largeCard),
      ),
      child: Column(
        children: [
          // Drag handle bar
          AppSpacing.verticalSm,
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.borderPill,
              ),
            ),
          ),

          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Vintage postal stamp
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_post_office_outlined,
                        size: 13,
                        color: AppColors.burgundy,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.postalStampDate,
                        style: AppTypography.captionSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.espresso,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Favorite button
                IconButton(
                  icon: Icon(
                    item.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: item.isFavorite
                        ? AppColors.burgundy
                        : AppColors.taupe,
                  ),
                  onPressed: onFavoriteToggle,
                ),

                // Edit button
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.espresso,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                ),

                // Close button
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.espresso,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Scrollable Letter Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Photo (if available) with interactive zoom
                  if (item.hasImage) ...[
                    _buildZoomableImage(context),
                    AppSpacing.verticalMd,
                  ],

                  // Category & Date Pills Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.category == 'Anniversary'
                              ? AppColors.burgundy
                              : AppColors.blushSand,
                          borderRadius: AppRadius.borderPill,
                        ),
                        child: Text(
                          item.category,
                          style: AppTypography.captionSmall.copyWith(
                            color: item.category == 'Anniversary'
                                ? AppColors.paper
                                : AppColors.espresso,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppSpacing.horizontalSm,
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.taupe,
                      ),
                      AppSpacing.horizontalXxs,
                      Text(
                        item.formattedDate,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.taupe,
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.verticalSm,

                  // Milestone Title
                  Text(
                    item.title,
                    style: AppTypography.h1.copyWith(
                      fontSize: 28,
                      color: AppColors.espresso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Location Tag
                  if (item.hasLocation) ...[
                    AppSpacing.verticalXs,
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: AppColors.burgundy,
                        ),
                        AppSpacing.horizontalXxs,
                        Expanded(
                          child: Text(
                            item.location!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.taupe,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  AppSpacing.verticalLg,

                  // Intimate Handwritten Love Note Section
                  if (item.hasNote) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        borderRadius: AppRadius.borderCard,
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.espresso.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite_border_rounded,
                                size: 16,
                                color: AppColors.dustyRose,
                              ),
                              AppSpacing.horizontalXs,
                              Text(
                                'A Dear Note',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.burgundy,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.verticalSm,
                          Text(
                            item.note,
                            style: AppTypography.handwrittenNote.copyWith(
                              fontSize: 23,
                              height: 1.35,
                              color: AppColors.espresso,
                            ),
                          ),
                          AppSpacing.verticalMd,

                          // Wax seal signature line
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Forever,',
                                  style: TextStyle(
                                    fontFamily: 'Caveat',
                                    fontSize: 18,
                                    color: AppColors.taupe,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                AppSpacing.horizontalXs,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.burgundy.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: AppRadius.borderPill,
                                  ),
                                  child: Text(
                                    item.authorName,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.burgundy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  AppSpacing.verticalXl,

                  // Footer action: Soft delete confirmation
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.taupe,
                      ),
                      label: Text(
                        'Let go of this chapter',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.taupe,
                        ),
                      ),
                      onPressed: () {
                        _confirmDelete(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomableImage(BuildContext context) {
    final imgUrl = item.imageUrl!;
    final isLocal =
        !imgUrl.startsWith('http://') && !imgUrl.startsWith('https://');
    final mediaQuery = MediaQuery.of(context);

    return GestureDetector(
      onTap: () {
        TimelinePhotoViewerDialog.show(
          context,
          imageUrl: imgUrl,
          title: item.title,
          location: item.location,
          date: item.formattedDate,
        );
      },
      child: ClipRRect(
        borderRadius: AppRadius.borderLargeCard,
        child: Container(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.48),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.ivory.withValues(alpha: 0.6),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              isLocal
                  ? (File(imgUrl).existsSync()
                        ? Image.file(
                            File(imgUrl),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.dustyRose,
                              size: 40,
                            ),
                          ))
                  : CachedNetworkImage(
                      imageUrl: imgUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      memCacheWidth: 1000,
                      placeholder: (context, url) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.burgundy,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.dustyRose,
                          size: 40,
                        ),
                      ),
                    ),

              // Actual Size tap hint badge
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.espresso.withValues(alpha: 0.7),
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fullscreen_rounded,
                        size: 14,
                        color: AppColors.paper,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Actual Size',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.paper,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderCard),
        title: Text(
          'Let Go of Memory?',
          style: AppTypography.h3.copyWith(color: AppColors.espresso),
        ),
        content: Text(
          'Are you sure you want to gently remove "${item.title}" from your couple timeline?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.taupe),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Keep Treasured',
              style: AppTypography.label.copyWith(color: AppColors.espresso),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.paper,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderButton,
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close sheet
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
