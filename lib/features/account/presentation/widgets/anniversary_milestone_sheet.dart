import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/anniversary_helper.dart';

/// Modal bottom sheet displaying Vicky & Puja's upcoming relationship milestones
/// and live ticking countdown clocks.
class AnniversaryMilestoneSheet extends StatefulWidget {
  final DateTime anniversaryDate;

  const AnniversaryMilestoneSheet({super.key, required this.anniversaryDate});

  static void show(BuildContext context, {required DateTime anniversaryDate}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          AnniversaryMilestoneSheet(anniversaryDate: anniversaryDate),
    );
  }

  @override
  State<AnniversaryMilestoneSheet> createState() =>
      _AnniversaryMilestoneSheetState();
}

class _AnniversaryMilestoneSheetState extends State<AnniversaryMilestoneSheet> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final milestones = AnniversaryHelper.getUpcomingMilestones(
      widget.anniversaryDate,
      now,
    );
    final daysTogether = AnniversaryHelper.calculateDaysTogether(
      widget.anniversaryDate,
      now,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.verticalMd,

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.blushSand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.burgundy,
                    size: 18,
                  ),
                ),
                AppSpacing.horizontalSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our Milestones',
                        style: AppTypography.h2.copyWith(
                          fontSize: 20,
                          color: AppColors.espresso,
                        ),
                      ),
                      Text(
                        '$daysTogether days of our beautiful story',
                        style: AppTypography.handwrittenCaption.copyWith(
                          fontSize: 14,
                          color: AppColors.taupe,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.taupe),
                ),
              ],
            ),

            AppSpacing.verticalMd,
            const Divider(),
            AppSpacing.verticalSm,

            // Upcoming Milestones List
            ...milestones.map((milestone) {
              final countdown = milestone.formattedCountdown(now);
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadius.borderCard,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blushSand,
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Text(
                            milestone.badge,
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.burgundy,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          milestone.formattedDate(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      milestone.title,
                      style: AppTypography.h3.copyWith(
                        fontSize: 17,
                        color: AppColors.espresso,
                      ),
                    ),
                    AppSpacing.verticalXxs,
                    Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 14,
                          color: AppColors.burgundy,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          countdown,
                          style: AppTypography.captionSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.burgundy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            AppSpacing.verticalSm,
          ],
        ),
      ),
    );
  }
}
