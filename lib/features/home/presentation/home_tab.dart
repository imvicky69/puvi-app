import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/home_header.dart';

/// The Home tab view featuring the top header and empty canvas layout.
class HomeTab extends StatelessWidget {
  final String userName;

  const HomeTab({super.key, this.userName = 'Vicky'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Component
            HomeHeader(userName: userName),

            const Divider(),

            // Empty Canvas body
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: AppSpacing.screenPadding,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.blushSand,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 36,
                            color: AppColors.dustyRose,
                          ),
                        ),
                        AppSpacing.verticalLg,
                        Text(
                          'Our sanctuary is ready',
                          style: AppTypography.h2.copyWith(
                            fontSize: 24,
                            color: AppColors.espresso,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.verticalXs,
                        Text(
                          'Your shared memories, countdowns, and love notes will blossom here.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.taupe,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.verticalXl,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Puvi • Love Letters',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.burgundy,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }
}
