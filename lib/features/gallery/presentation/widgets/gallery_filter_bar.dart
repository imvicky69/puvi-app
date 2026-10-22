import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_repository.dart';

/// Filter selection bar for switching between All, Photos, Videos, and Favorites.
class GalleryFilterBar extends StatelessWidget {
  final GalleryFilter activeFilter;
  final ValueChanged<GalleryFilter> onFilterChanged;
  final int totalCount;
  final int photosCount;
  final int videosCount;
  final int favoritesCount;

  const GalleryFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.photosCount,
    required this.videosCount,
    required this.favoritesCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'All ($totalCount)',
            isSelected: activeFilter == GalleryFilter.all,
            onTap: () => onFilterChanged(GalleryFilter.all),
          ),
          AppSpacing.horizontalSm,
          _FilterChip(
            label: 'Photos ($photosCount)',
            icon: Icons.photo_outlined,
            isSelected: activeFilter == GalleryFilter.photos,
            onTap: () => onFilterChanged(GalleryFilter.photos),
          ),
          AppSpacing.horizontalSm,
          _FilterChip(
            label: 'Videos ($videosCount)',
            icon: Icons.videocam_outlined,
            isSelected: activeFilter == GalleryFilter.videos,
            onTap: () => onFilterChanged(GalleryFilter.videos),
          ),
          AppSpacing.horizontalSm,
          _FilterChip(
            label: 'Favorites ($favoritesCount)',
            icon: Icons.favorite_rounded,
            isSelected: activeFilter == GalleryFilter.favorites,
            onTap: () => onFilterChanged(GalleryFilter.favorites),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.burgundy : AppColors.paper,
          borderRadius: AppRadius.borderPill,
          border: Border.all(
            color: isSelected ? AppColors.burgundy : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.burgundy.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.espresso,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.espresso,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
