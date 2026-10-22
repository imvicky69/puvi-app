import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Card showing the couple's anniversary, days together, and love stats.
class CoupleStatsCard extends StatelessWidget {
  final DateTime anniversaryDate;
  final int loveCount;
  final int totalMemories;

  const CoupleStatsCard({
    super.key,
    required this.anniversaryDate,
    this.loveCount = 272000,
    this.totalMemories = 177,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(anniversaryDate).inDays.abs();

    return Card(
      color: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderCard,
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Column(
          children: [
            // Anniversary Header
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.burgundy,
                ),
                AppSpacing.horizontalXs,
                Text(
                  'Together Since',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                const Spacer(),
                Text(
                  'April 11, 2026',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            AppSpacing.verticalMd,

            // 3-Column Metrics Row
            Row(
              children: [
                _StatTile(
                  label: 'Days of Love',
                  value: '$difference',
                  icon: Icons.favorite_border_rounded,
                ),
                _VerticalDivider(),
                _StatTile(
                  label: 'Love Taps',
                  value: '272k',
                  icon: Icons.touch_app_outlined,
                ),
                _VerticalDivider(),
                _StatTile(
                  label: 'Memories',
                  value: '$totalMemories',
                  icon: Icons.photo_library_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.taupe),
          AppSpacing.verticalXxs,
          Text(
            value,
            style: AppTypography.h3.copyWith(
              fontSize: 18,
              color: AppColors.espresso,
            ),
          ),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.taupe,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.border);
  }
}
