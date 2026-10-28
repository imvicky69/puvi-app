import 'package:flutter/material.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/widgets/app_update_banner.dart';
import 'app_update_sheet.dart';

/// Settings and preferences section with dummy switches and configuration tiles.
/// Now features live version & build number display with automatic GitHub update checking.
class AppSettingsSection extends StatefulWidget {
  final bool initialAppLock;
  final String appLockPin;

  const AppSettingsSection({
    super.key,
    this.initialAppLock = true,
    this.appLockPin = '6987',
  });

  @override
  State<AppSettingsSection> createState() => _AppSettingsSectionState();
}

class _AppSettingsSectionState extends State<AppSettingsSection> {
  late bool _appLockEnabled;
  bool _notificationsEnabled = true;
  String _version = '1.0.0';
  String _buildNumber = '1';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _appLockEnabled = widget.initialAppLock;

    // 1. Fetch live app version & build number from package_info_plus
    AppUpdateService.getPackageInfo().then((pkg) {
      if (mounted) {
        setState(() {
          _version = pkg.version;
          _buildNumber = pkg.buildNumber;
        });
      }
    });

    // 2. Check for newer GitHub releases in the background (skip in test environment)
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
              // App Lock PIN Toggle
              SwitchListTile(
                value: _appLockEnabled,
                activeThumbColor: AppColors.burgundy,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 2,
                ),
                secondary: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
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
                  _appLockEnabled
                      ? 'Passcode PIN: •••• (${widget.appLockPin})'
                      : 'Disabled',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _appLockEnabled = val);
                },
              ),

              const Divider(height: 1),

              // Love Pings & Notifications
              SwitchListTile(
                value: _notificationsEnabled,
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
                  'Receive instant pings and notes',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _notificationsEnabled = val);
                },
              ),

              const Divider(height: 1),

              // Daily Reminder Time
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: AppColors.espresso,
                ),
                title: Text(
                  'Daily Love Reminder',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                trailing: Text(
                  '9:00 PM',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Daily reminder scheduled for 9:00 PM 💕'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const Divider(height: 1),

              // Offline Sync Status
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.cloud_done_outlined,
                  size: 20,
                  color: AppColors.espresso,
                ),
                title: Text(
                  'Cloud Sync',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                trailing: Text(
                  '177 synced',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Divider(height: 1),

              // Live App Version with Update Status Indicator
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
