import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/anniversary_helper.dart';
import 'anniversary_milestone_sheet.dart';

/// Aesthetic, romantic stationery card celebrating Vicky & Puja's anniversary,
/// exact live days together, and real-time ticking milestone countdown.
class CoupleStatsCard extends StatefulWidget {
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
  State<CoupleStatsCard> createState() => _CoupleStatsCardState();
}

class _CoupleStatsCardState extends State<CoupleStatsCard> {
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    // Live ticking countdown updating every second
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  String _formatAnniversaryDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Unified exact calculation matching the Home Screen
    final daysTogether = AnniversaryHelper.calculateDaysTogether(
      widget.anniversaryDate,
      now,
    );
    final upcomingMilestones = AnniversaryHelper.getUpcomingMilestones(
      widget.anniversaryDate,
      now,
    );
    final nextMilestone = upcomingMilestones.isNotEmpty
        ? upcomingMilestones.first
        : null;

    final formattedDateStr = _formatAnniversaryDate(widget.anniversaryDate);

    return InkWell(
      onTap: () => AnniversaryMilestoneSheet.show(
        context,
        anniversaryDate: widget.anniversaryDate,
      ),
      borderRadius: AppRadius.borderCard,
      child: Card(
        color: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderCard,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Anniversary Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: const BoxDecoration(
                      color: AppColors.blushSand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.burgundy,
                    ),
                  ),
                  AppSpacing.horizontalXs,
                  Text(
                    'Together Since',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.espresso,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Preserves exact "April 11, 2026" text for widget tests while formatted dynamically
                  Text(
                    formattedDateStr,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalSm,
              const Divider(height: 1),
              AppSpacing.verticalMd,

              // 2. Central Live Days Hero & Romantic Note
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blushSand,
                      borderRadius: AppRadius.borderCard,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$daysTogether',
                          style: AppTypography.display.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.espresso,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Days of Love',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.burgundy,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Our Forever Journey',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.espresso,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '“Two souls, one heartbeat • Vicky & Puja”',
                          style: AppTypography.handwrittenCaption.copyWith(
                            fontSize: 13,
                            color: AppColors.taupe,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. Cute Next Milestone Ticker
              if (nextMilestone != null) ...[
                AppSpacing.verticalMd,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: AppRadius.borderPill,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 14,
                        color: AppColors.burgundy,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${nextMilestone.badge} in ${nextMilestone.formattedCountdown(now)}',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.taupe,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
