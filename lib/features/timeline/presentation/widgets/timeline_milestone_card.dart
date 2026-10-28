import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/puvi_avatar.dart';
import '../../data/timeline_item.dart';
import 'timeline_photo_viewer_dialog.dart';

/// Aesthetic vintage love-letter postcard milestone card.
class TimelineMilestoneCard extends StatelessWidget {
  final TimelineItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TimelineMilestoneCard({
    super.key,
    required this.item,
    this.isFirst = false,
    this.isLast = false,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Romantic timeline spine (stitch line with stamp marker)
          _buildTimelineSpine(),
          AppSpacing.horizontalMd,

          // Main postcard love-letter card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildPostcardCard(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the left-hand timeline connector spine with a vintage heart stamp marker
  Widget _buildTimelineSpine() {
    return SizedBox(
      width: 32,
      child: Column(
        children: [
          // Top connector line
          Expanded(
            flex: isFirst ? 1 : 2,
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : AppColors.border,
            ),
          ),

          // Central romantic node marker
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.category == 'Anniversary'
                  ? AppColors.burgundy
                  : AppColors.paper,
              shape: BoxShape.circle,
              border: Border.all(
                color: item.category == 'Anniversary'
                    ? AppColors.burgundy
                    : AppColors.dustyRose,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espresso.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                item.category == 'Anniversary'
                    ? Icons.favorite_rounded
                    : (item.hasImage
                          ? Icons.photo_camera_rounded
                          : Icons.auto_stories_rounded),
                size: 14,
                color: item.category == 'Anniversary'
                    ? AppColors.paper
                    : AppColors.burgundy,
              ),
            ),
          ),

          // Bottom connector line
          Expanded(
            flex: 8,
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main love-letter postcard surface
  Widget _buildPostcardCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderCard,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: AppRadius.borderCard,
            border: Border.all(
              color: item.category == 'Anniversary'
                  ? AppColors.dustyRose.withValues(alpha: 0.6)
                  : AppColors.border,
              width: item.category == 'Anniversary' ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Postcard Stamp Header & Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm + 2,
                  AppSpacing.xs,
                  AppSpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Wrap postal stamp and category badge so they never overflow
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [_buildPostalStamp(), _buildCategoryBadge()],
                      ),
                    ),

                    // Actions: Favorite & Context Menu
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              item.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: item.isFavorite
                                  ? AppColors.burgundy
                                  : AppColors.taupe.withValues(alpha: 0.5),
                              size: 19,
                            ),
                            onPressed: onFavoriteToggle,
                          ),
                        ),
                        SizedBox(
                          width: 26,
                          height: 32,
                          child: _buildPopupMenu(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Attached Photo (if any)
              if (item.hasImage) ...[
                AppSpacing.verticalXs,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: _buildMilestoneImage(context),
                ),
              ],

              // Milestone Title
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Text(
                  item.title,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Handwritten Love Note Excerpt
              if (item.hasNote) ...[
                AppSpacing.verticalXs,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ivory.withValues(alpha: 0.5),
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      item.note,
                      style: AppTypography.handwrittenNote.copyWith(
                        fontSize: 20,
                        color: AppColors.espresso.withValues(alpha: 0.9),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],

              // Footer Metadata: Location & Author Stamp
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    if (item.hasLocation) ...[
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppColors.burgundy,
                      ),
                      AppSpacing.horizontalXxs,
                      Expanded(
                        child: Text(
                          item.location!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.taupe,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.taupe,
                      ),
                      AppSpacing.horizontalXxs,
                      Expanded(
                        child: Text(
                          item.formattedDate,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.taupe,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    AppSpacing.horizontalSm,

                    // Author Initial Stamp
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blushSand.withValues(alpha: 0.6),
                        borderRadius: AppRadius.borderPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.authorName.toLowerCase() == 'vicky')
                            const Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: PuviAvatar.vicky(
                                size: 14,
                                showBorder: false,
                              ),
                            )
                          else if (item.authorName.toLowerCase() == 'puja')
                            const Padding(
                              padding: EdgeInsets.only(right: 3),
                              child: PuviAvatar.puja(
                                size: 14,
                                showBorder: false,
                              ),
                            )
                          else
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 12,
                              color: AppColors.burgundy,
                            ),
                          const SizedBox(width: 3),
                          Text(
                            item.authorName,
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.burgundy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  /// Builds a postal cancellation date stamp
  Widget _buildPostalStamp() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_post_office_outlined,
            size: 11,
            color: AppColors.burgundy,
          ),
          const SizedBox(width: 4),
          Text(
            item.postalStampDate,
            style: AppTypography.captionSmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 10,
              color: AppColors.espresso,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds category tag badge
  Widget _buildCategoryBadge() {
    Color bg;
    Color fg;
    switch (item.category.toLowerCase()) {
      case 'anniversary':
        bg = AppColors.burgundy;
        fg = AppColors.paper;
        break;
      case 'firsts':
        bg = AppColors.dustyRose.withValues(alpha: 0.4);
        fg = AppColors.espresso;
        break;
      case 'milestones':
        bg = AppColors.blushSand;
        fg = AppColors.espresso;
        break;
      case 'long distance':
        bg = AppColors.taupe.withValues(alpha: 0.15);
        fg = AppColors.espresso;
        break;
      case 'love notes':
        bg = AppColors.dustyRose.withValues(alpha: 0.25);
        fg = AppColors.burgundy;
        break;
      default:
        bg = AppColors.blushSand.withValues(alpha: 0.8);
        fg = AppColors.espresso;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.borderPill),
      child: Text(
        item.category,
        style: AppTypography.captionSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Builds the milestone photograph with natural aspect-ratio preservation
  Widget _buildMilestoneImage(BuildContext context) {
    final imgUrl = item.imageUrl!;
    final isLocal =
        !imgUrl.startsWith('http://') && !imgUrl.startsWith('https://');

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
        borderRadius: AppRadius.borderButton,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 480),
          decoration: BoxDecoration(
            color: AppColors.ivory.withValues(alpha: 0.6),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.7),
              width: 0.8,
            ),
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
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder())
                  : CachedNetworkImage(
                      imageUrl: imgUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      memCacheWidth: 1000,
                      placeholder: (context, url) => Container(
                        height: 220,
                        width: double.infinity,
                        color: AppColors.ivory,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.burgundy,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildImagePlaceholder(),
                    ),

              // Full size preview indicator badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
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
                        size: 13,
                        color: AppColors.paper,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Full size',
                        style: TextStyle(
                          fontSize: 10,
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.ivory,
      child: const Center(
        child: Icon(Icons.photo_outlined, color: AppColors.dustyRose, size: 32),
      ),
    );
  }

  /// Context popup menu for editing or removing
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: AppColors.taupe,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      color: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderButton,
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.espresso,
              ),
              AppSpacing.horizontalSm,
              Text(
                'Edit Chapter',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.espresso,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.error,
              ),
              AppSpacing.horizontalSm,
              Text(
                'Let Go',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
