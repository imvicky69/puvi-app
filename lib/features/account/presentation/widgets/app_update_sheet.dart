import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Modal bottom sheet displaying update details, changelog,
/// live download progress bar, and one-click package installer execution.
class AppUpdateSheet extends StatefulWidget {
  final AppReleaseInfo release;
  final String currentVersion;
  final String currentBuild;

  const AppUpdateSheet({
    super.key,
    required this.release,
    required this.currentVersion,
    required this.currentBuild,
  });

  static Future<void> show(
    BuildContext context, {
    required AppReleaseInfo release,
    required String currentVersion,
    required String currentBuild,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppUpdateSheet(
        release: release,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      ),
    );
  }

  @override
  State<AppUpdateSheet> createState() => _AppUpdateSheetState();
}

class _AppUpdateSheetState extends State<AppUpdateSheet> {
  bool _isDownloading = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  File? _downloadedApk;

  Future<void> _startDownloadAndInstall() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    final file = await AppUpdateService.downloadApk(
      widget.release,
      onProgress: (progress, received, total) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _receivedBytes = received;
            _totalBytes = total;
          });
        }
      },
    );

    if (!mounted) return;

    if (file == null) {
      setState(() {
        _isDownloading = false;
        _errorMessage =
            'Download could not be completed. Please check connection.';
      });
      return;
    }

    setState(() {
      _isDownloading = false;
      _downloadedApk = file;
    });

    // 1. Success haptic burst
    HapticFeedback.heavyImpact();

    // 2. Immediately trigger Android package installer
    await AppUpdateService.installApk(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final mbReceived = (_receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final mbTotal = _totalBytes > 0
        ? (_totalBytes / (1024 * 1024)).toStringAsFixed(1)
        : release.formattedFileSize;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Grab handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              AppSpacing.verticalMd,

              // 2. Header Icon & Badge
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.blushSand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 26,
                  color: AppColors.burgundy,
                ),
              ),

              AppSpacing.verticalSm,

              Text(
                'New Puvi Update Available',
                style: AppTypography.h2.copyWith(
                  fontSize: 22,
                  color: AppColors.espresso,
                ),
              ),

              AppSpacing.verticalXxs,

              Text(
                'Crafted with love for Puja & Vicky 💕',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.taupe,
                ),
              ),

              AppSpacing.verticalLg,

              // 3. Version Comparison Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadius.borderCard,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Current Version',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.taupe,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'v${widget.currentVersion}+${widget.currentBuild}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.dustyRose,
                      size: 20,
                    ),
                    Column(
                      children: [
                        Text(
                          'Latest Release',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'v${release.version}${release.buildNumber != null ? "+${release.buildNumber}" : ""}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              AppSpacing.verticalSm,

              // 4. Architecture and File Size Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blushSand.withValues(alpha: 0.6),
                      borderRadius: AppRadius.borderPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.memory_rounded,
                          size: 13,
                          color: AppColors.espresso,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${release.architecture} • ${release.formattedFileSize}',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalMd,

              // 5. Release Notes / Changelog
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What\'s New',
                  style: AppTypography.label.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    release.releaseNotes.trim().isNotEmpty
                        ? release.releaseNotes
                        : 'Fresh romantic updates, smoother animations, and stability enhancements 💕',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.espresso,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                AppSpacing.verticalSm,
                Text(
                  _errorMessage!,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              AppSpacing.verticalLg,

              // 6. Action Button / Progress Bar
              if (_isDownloading) ...[
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 10,
                        backgroundColor: AppColors.blushSand,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.burgundy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Downloading: ${(_progress * 100).toInt()}% ($mbReceived MB / $mbTotal MB)',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else if (_downloadedApk != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        AppUpdateService.installApk(_downloadedApk!.path),
                    icon: const Icon(Icons.install_mobile_rounded, size: 20),
                    label: const Text('Install Update Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startDownloadAndInstall,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('One-Click Download & Install'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burgundy,
                      foregroundColor: AppColors.paper,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],

              AppSpacing.verticalXs,

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
