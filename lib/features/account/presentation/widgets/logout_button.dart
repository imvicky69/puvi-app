import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/data/auth_session_manager.dart';
import '../../../auth/login_screen.dart';

/// Logout button with a themed confirmation dialog.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderCard,
            side: BorderSide(color: AppColors.border, width: 1),
          ),
          title: Text(
            'Sign out of Puvi?',
            style: AppTypography.h2.copyWith(
              fontSize: 22,
              color: AppColors.espresso,
            ),
          ),
          content: Text(
            'You can sign back in anytime to cherish our shared story.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.taupe,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Stay',
                style: AppTypography.label.copyWith(color: AppColors.taupe),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthSessionManager.clearSession();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: AppColors.paper,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderButton,
                ),
                elevation: 0,
              ),
              child: Text(
                'Sign Out',
                style: AppTypography.label.copyWith(
                  color: AppColors.paper,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderButton,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
            AppSpacing.horizontalSm,
            Text(
              'Sign Out',
              style: AppTypography.label.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
