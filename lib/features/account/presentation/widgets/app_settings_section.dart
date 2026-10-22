import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Settings and preferences section with dummy switches and configuration tiles.
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

  @override
  void initState() {
    super.initState();
    _appLockEnabled = widget.initialAppLock;
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

              // App Version
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.espresso,
                ),
                title: Text(
                  'Puvi Edition',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                trailing: Text(
                  'v1.0.0 • Love Letters',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
