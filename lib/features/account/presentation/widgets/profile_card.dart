import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

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
    final isVicky = userName.toLowerCase().contains('vicky');
    final userAsset = isVicky ? 'assets/puvi-1.jpeg' : 'assets/puvi-2.jpeg';
    final partnerAsset = isVicky ? 'assets/puvi-2.jpeg' : 'assets/puvi-1.jpeg';

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
            // Row of Two Partners
            Row(
              children: [
                // Current User
                Expanded(
                  child: _UserAvatarColumn(
                    name: userName,
                    email: userEmail,
                    roleLabel: 'You',
                    assetPath: userAsset,
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
                    assetPath: partnerAsset,
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
  final String assetPath;

  const _UserAvatarColumn({
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espresso.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.blushSand,
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0] : 'P',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.burgundy,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: AppRadius.borderPill,
                border: Border.all(color: AppColors.border, width: 1),
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
