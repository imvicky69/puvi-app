import 'package:flutter/material.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'verify_pin_dialog.dart';

/// Full-screen lock gate for Puvi, unlocking via Fingerprint / Face ID or backup PIN.
class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Automatically prompt biometrics on appearance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final success = await AppLockService.authenticateWithBiometrics(
      reason: 'Scan your fingerprint or face to open Our Sanctuary 💕',
    );

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (success) {
      widget.onUnlocked();
    }
  }

  Future<void> _openPinUnlock() async {
    final success = await VerifyPinDialog.show(
      context,
      title: 'Enter Backup PIN',
      subtitle: 'Unlock Puvi with your 4-digit PIN',
    );
    if (success && mounted) {
      widget.onUnlocked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Medallion
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espresso.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.burgundy,
                      size: 36,
                    ),
                  ),

                  AppSpacing.verticalLg,

                  Text(
                    'Puvi Sanctuary',
                    style: AppTypography.display.copyWith(
                      fontSize: 32,
                      color: AppColors.espresso,
                      letterSpacing: -0.5,
                    ),
                  ),

                  AppSpacing.verticalXxs,

                  Text(
                    '“Protected with love • Vicky & Puja”',
                    style: AppTypography.handwrittenCaption.copyWith(
                      fontSize: 16,
                      color: AppColors.taupe,
                    ),
                  ),

                  AppSpacing.verticalXxl,

                  // Biometric Unlock Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _tryBiometricUnlock,
                      icon: const Icon(Icons.fingerprint_rounded, size: 22),
                      label: Text(
                        'Unlock with Biometrics',
                        style: AppTypography.label.copyWith(
                          color: AppColors.paper,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.burgundy,
                        foregroundColor: AppColors.paper,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderButton,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  AppSpacing.verticalMd,

                  // PIN Fallback
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openPinUnlock,
                      icon: const Icon(Icons.dialpad_rounded, size: 18),
                      label: Text(
                        'Use Backup PIN',
                        style: AppTypography.label.copyWith(
                          color: AppColors.espresso,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.paper,
                        foregroundColor: AppColors.espresso,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.2,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderButton,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
