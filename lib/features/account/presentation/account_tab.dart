import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Minimal placeholder for the Account tab.
class AccountTab extends StatelessWidget {
  final String userName;

  const AccountTab({super.key, this.userName = 'Vicky'});

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
                    'Account',
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
                        Icons.favorite_outline_rounded,
                        size: 40,
                        color: AppColors.dustyRose,
                      ),
                      AppSpacing.verticalMd,
                      Text(
                        'Couple Profile',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.espresso,
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'Anniversary, lock settings, and companion sync.',
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
