import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Minimal placeholder for the Timeline tab.
class TimelineTab extends StatelessWidget {
  const TimelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Tab Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              color: AppColors.ivory,
              child: Row(
                children: [
                  Text(
                    'Timeline',
                    style: AppTypography.h1.copyWith(
                      fontSize: 26,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        size: 40,
                        color: AppColors.dustyRose,
                      ),
                      AppSpacing.verticalMd,
                      Text(
                        'Milestones & Chapters',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.espresso,
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'Every special chapter of our story will be treasured here.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.taupe,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
