import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

import '../../../../core/widgets/puvi_avatar.dart';

/// Displays the couple profile cards linking the active user and their partner.
class ProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String partnerName;
  final String partnerEmail;

  const ProfileCard({
    super.key,
    this.userName = 'Vicky',
    this.userEmail = 'vicky@puvi.com',
    this.partnerName = 'Puja',
    this.partnerEmail = 'puja@puvi.com',
  });

  @override
  Widget build(BuildContext context) {
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
            // Row of Two Partners with Mascot Profiles
            Row(
              children: [
                // Current User
                Expanded(
                  child: _UserAvatarColumn(
                    name: userName,
                    email: userEmail,
                    roleLabel: 'You',
                  ),
                ),

                // Connected Heart Medallion
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

                // Partner
                Expanded(
                  child: _UserAvatarColumn(
                    name: partnerName,
                    email: partnerEmail,
                    roleLabel: 'Partner',
                  ),
                ),
              ],
            ),

            AppSpacing.verticalMd,
            const Divider(),
            AppSpacing.verticalSm,

            // Connection Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.horizontalXs,
                Text(
                  'Connected & In Sync',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.taupe,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatarColumn extends StatelessWidget {
  final String name;
  final String email;
  final String roleLabel;

  const _UserAvatarColumn({
    required this.name,
    required this.email,
    required this.roleLabel,
  });

  void _showMascotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isVicky = PuviAvatar.isVicky(name);
        final title = isVicky ? 'Vicky • The Protector' : 'Puja • The Sunshine';
        final quote = isVicky
            ? '“Loved by Puja, forever & always.”'
            : '“Cherished by Vicky, with every heartbeat.”';

        return AlertDialog(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderLargeCard,
            side: BorderSide(color: AppColors.border, width: 1.2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.verticalSm,
              PuviAvatar(
                nameOrUid: name,
                size: 110,
                showBorder: true,
                borderWidth: 2.5,
                borderColor: AppColors.dustyRose,
                showShadow: true,
                backgroundColor: AppColors.ivory,
              ),
              AppSpacing.verticalMd,
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  fontSize: 18,
                  color: AppColors.espresso,
                ),
              ),
              AppSpacing.verticalXs,
              Text(
                quote,
                textAlign: TextAlign.center,
                style: AppTypography.handwrittenCaption.copyWith(
                  fontSize: 16,
                  color: AppColors.taupe,
                ),
              ),
              AppSpacing.verticalSm,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blushSand,
                  borderRadius: AppRadius.borderPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 12,
                      color: AppColors.burgundy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Official Couple Mascot',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: AppTypography.label.copyWith(color: AppColors.burgundy),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            PuviAvatar(
              nameOrUid: name,
              size: 68,
              showBorder: true,
              borderWidth: 2.0,
              borderColor: AppColors.border,
              showShadow: true,
              backgroundColor: AppColors.ivory,
              onTap: () => _showMascotDialog(context),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: AppRadius.borderPill,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espresso.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                roleLabel,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.burgundy,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.verticalXs,
        Text(
          name,
          style: AppTypography.h3.copyWith(
            fontSize: 17,
            color: AppColors.espresso,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          email,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.taupe,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
