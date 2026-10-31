import 'package:flutter/material.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/fcm_token_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/widgets/app_update_banner.dart';
import 'app_update_sheet.dart';
import 'set_backup_pin_dialog.dart';
import 'verify_pin_dialog.dart';

/// Clean, minimal, and fully live settings and security section for Puvi.
///
/// Features:
/// - Biometric & 4-digit backup PIN App Lock (default: OFF).
/// - Live Firestore-backed Love Notifications toggle.
/// - Live app version and automatic GitHub update detection.
class AppSettingsSection extends StatefulWidget {
  final String userName;
  final bool initialAppLock;
  final String appLockPin;

  const AppSettingsSection({
    super.key,
    this.userName = 'Vicky',
    this.initialAppLock = false,
    this.appLockPin = '6987',
  });

  @override
  State<AppSettingsSection> createState() => _AppSettingsSectionState();
}

class _AppSettingsSectionState extends State<AppSettingsSection> {
  String _version = '1.0.1';
  String _buildNumber = '2';
  bool _isCheckingUpdate = false;
  bool _isLockActionPending = false;

  @override
  void initState() {
    super.initState();

    // 1. Initialize local AppLockService preferences
    AppLockService.initialize();

    // 2. Fetch live app version & build number from package_info_plus
    AppUpdateService.getPackageInfo().then((pkg) {
      if (mounted) {
        setState(() {
          _version = pkg.version;
          _buildNumber = pkg.buildNumber;
        });
      }
    });

    // 3. Check for newer GitHub releases in the background (skip in test runner)
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTesting) {
      AppUpdateService.checkForUpdate().then((update) {
        if (mounted && update != null) {
          AppUpdateBanner.show(
            context,
            release: update,
            currentVersion: _version,
            currentBuild: _buildNumber,
          );
        }
      });
    }
  }

  Future<void> _handleAppLockToggle(bool turnOn) async {
    if (_isLockActionPending) return;
    setState(() => _isLockActionPending = true);

    try {
      if (turnOn) {
        // Step 1: Prompt biometric enrollment / scan if device supports it
        final canBiometric =
            await AppLockService.canAuthenticateWithBiometrics();
        if (canBiometric) {
          final authOk = await AppLockService.authenticateWithBiometrics(
            reason: 'Authenticate with fingerprint or face to enable App Lock',
          );
          if (!authOk) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometric verification cancelled.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        }

        // Step 2: Prompt to set a 4-digit backup PIN
        if (!mounted) return;
        final pin = await SetBackupPinDialog.show(context);
        if (pin != null && pin.isNotEmpty) {
          await AppLockService.enableLock(
            pin: pin,
            useBiometrics: canBiometric,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'App Lock enabled with biometric & PIN protection 💕',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Disabling requires biometric or PIN verification
        bool verified = false;
        final canBiometric =
            await AppLockService.canAuthenticateWithBiometrics();
        if (canBiometric) {
          verified = await AppLockService.authenticateWithBiometrics(
            reason: 'Authenticate to turn off App Lock',
          );
        }

        if (!verified && mounted) {
          verified = await VerifyPinDialog.show(
            context,
            title: 'Turn Off App Lock',
            subtitle: 'Enter your 4-digit backup PIN to confirm',
          );
        }

        if (verified) {
          await AppLockService.disableLock();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('App Lock turned off'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLockActionPending = false);
      }
    }
  }

  Future<void> _changeBackupPin() async {
    final verified = await VerifyPinDialog.show(
      context,
      title: 'Verify Current PIN',
      subtitle: 'Enter your current PIN to change it',
    );
    if (!verified || !mounted) return;

    final newPin = await SetBackupPinDialog.show(context);
    if (newPin != null && newPin.isNotEmpty) {
      await AppLockService.enableLock(
        pin: newPin,
        useBiometrics: AppLockService.useBiometrics,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup PIN updated successfully 💕'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleVersionTap() async {
    final currentUpdate = AppUpdateService.latestUpdateNotifier.value;
    if (currentUpdate != null) {
      AppUpdateSheet.show(
        context,
        release: currentUpdate,
        currentVersion: _version,
        currentBuild: _buildNumber,
      );
      return;
    }

    setState(() => _isCheckingUpdate = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.paper),
              ),
            ),
            SizedBox(width: 10),
            Text('Checking for newer Puvi updates on GitHub...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final update = await AppUpdateService.checkForUpdate();
    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (update != null) {
      AppUpdateSheet.show(
        context,
        release: update,
        currentVersion: _version,
        currentBuild: _buildNumber,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Puvi is up to date (v$_version+$_buildNumber) 💕'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Preferences & Security',
            style: AppTypography.label.copyWith(
              fontSize: 13,
              color: AppColors.taupe,
              letterSpacing: 0.2,
            ),
          ),
        ),
        AppSpacing.verticalSm,
        Card(
          color: AppColors.paper,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderCard,
            side: BorderSide(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              // 1. App Lock with Biometrics & Backup PIN (Default: OFF)
              ValueListenableBuilder<bool>(
                valueListenable: AppLockService.isEnabledNotifier,
                builder: (context, isLockEnabled, _) {
                  return SwitchListTile(
                    value: isLockEnabled,
                    activeThumbColor: AppColors.burgundy,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 2,
                    ),
                    secondary: const Icon(
                      Icons.fingerprint_rounded,
                      size: 22,
                      color: AppColors.espresso,
                    ),
                    title: Text(
                      'App Lock',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    subtitle: Text(
                      isLockEnabled
                          ? 'Biometric & PIN Protected'
                          : 'Disabled (Default)',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.taupe,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: (val) => _handleAppLockToggle(val),
                  );
                },
              ),

              ValueListenableBuilder<bool>(
                valueListenable: AppLockService.isEnabledNotifier,
                builder: (context, isLockEnabled, _) {
                  if (!isLockEnabled) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        leading: const Icon(
                          Icons.dialpad_rounded,
                          size: 18,
                          color: AppColors.burgundy,
                        ),
                        title: Text(
                          'Change 4-Digit Backup PIN',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.taupe,
                        ),
                        onTap: _changeBackupPin,
                      ),
                    ],
                  );
                },
              ),

              const Divider(height: 1),

              // 2. Live Love Notifications Synced to Firestore users/{uid}
              StreamBuilder<bool>(
                stream: FcmTokenService.watchNotificationsEnabled(
                  userName: widget.userName,
                ),
                initialData: true,
                builder: (context, snapshot) {
                  final notificationsOn = snapshot.data ?? true;
                  return SwitchListTile(
                    value: notificationsOn,
                    activeThumbColor: AppColors.burgundy,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 2,
                    ),
                    secondary: const Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: AppColors.espresso,
                    ),
                    title: Text(
                      'Love Notifications',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.espresso,
                      ),
                    ),
                    subtitle: Text(
                      notificationsOn
                          ? 'Instant pings, notes & love showers'
                          : 'Muted in our sanctuary',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.taupe,
                      ),
                    ),
                    onChanged: (val) {
                      FcmTokenService.setNotificationsEnabled(
                        userName: widget.userName,
                        enabled: val,
                      );
                    },
                  );
                },
              ),

              const Divider(height: 1),

              // 3. Live App Version with Update Status Indicator
              ValueListenableBuilder<AppReleaseInfo?>(
                valueListenable: AppUpdateService.latestUpdateNotifier,
                builder: (context, update, _) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 2,
                    ),
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.espresso,
                    ),
                    title: Row(
                      children: [
                        Text(
                          'Puvi Edition',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.espresso,
                          ),
                        ),
                        if (update != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.burgundy,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 10,
                                  color: AppColors.paper,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'v${update.version}',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.paper,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'v$_version (Build $_buildNumber) • Love Letters',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.taupe,
                      ),
                    ),
                    trailing: _isCheckingUpdate
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.burgundy,
                              ),
                            ),
                          )
                        : (update != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.blushSand,
                                    borderRadius: AppRadius.borderPill,
                                    border: Border.all(
                                      color: AppColors.burgundy,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Update ⚡',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.burgundy,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.taupe,
                                  size: 20,
                                )),
                    onTap: _handleVersionTap,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
