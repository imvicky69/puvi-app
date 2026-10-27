import 'package:flutter/material.dart';
import '../../../core/services/love_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/app_settings_section.dart';
import 'widgets/couple_stats_card.dart';
import 'widgets/logout_button.dart';
import 'widgets/profile_card.dart';

/// Full-featured, modular Account & Couple Profile screen.
///
/// Features:
/// - Connected Couple Profile card (Vicky & Puja).
/// - Anniversary and live days-together metrics.
/// - Security and dummy app preferences.
/// - Themed logout confirmation.
class AccountTab extends StatelessWidget {
  final String userName;

  const AccountTab({super.key, this.userName = 'Vicky'});

  @override
  Widget build(BuildContext context) {
    final isVicky = userName.toLowerCase().contains('vicky');
    final activeUserName = isVicky ? 'Vicky' : 'Puja';
    final activeUserEmail = isVicky ? 'vicky@puvi.com' : 'puja@puvi.com';
    final partnerName = isVicky ? 'Puja' : 'Vicky';
    final partnerEmail = isVicky ? 'puja@puvi.com' : 'vicky@puvi.com';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // Top Tab Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              color: AppColors.ivory,
              child: Row(
                children: [
                  Text(
                    'Profile & Settings',
                    style: AppTypography.h1.copyWith(
                      fontSize: 24,
                      color: AppColors.espresso,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Couple Profile Card
                        ProfileCard(
                          userName: activeUserName,
                          userEmail: activeUserEmail,
                          partnerName: partnerName,
                          partnerEmail: partnerEmail,
                        ),

                        AppSpacing.verticalMd,

                        // 2. Anniversary & Love Metrics
                        StreamBuilder<int>(
                          stream: LoveStatsService.watchLoveCount(),
                          initialData: LoveStatsService.currentLoveCount,
                          builder: (context, snapshot) {
                            return CoupleStatsCard(
                              anniversaryDate: DateTime(2026, 4, 11),
                              loveCount:
                                  snapshot.data ??
                                  LoveStatsService.currentLoveCount,
                              totalMemories: 177,
                            );
                          },
                        ),

                        AppSpacing.verticalLg,

                        // 3. App Settings & Security Section
                        const AppSettingsSection(
                          initialAppLock: true,
                          appLockPin: '6987',
                        ),

                        AppSpacing.verticalXl,

                        // 4. Logout Action
                        const LogoutButton(),

                        AppSpacing.verticalLg,

                        // Cute Footer
                        Center(
                          child: Text(
                            'Puvi • crafted for Vicky & Puja 💕',
                            style: AppTypography.handwrittenCaption.copyWith(
                              fontSize: 14,
                              color: AppColors.taupe,
                            ),
                          ),
                        ),

                        AppSpacing.verticalMd,
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
