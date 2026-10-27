import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../account/presentation/widgets/app_update_sheet.dart';

/// Top floating update banner that auto-dismisses after 5 seconds
/// or opens [AppUpdateSheet] when tapped.
class AppUpdateBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required AppReleaseInfo release,
    required String currentVersion,
    required String currentBuild,
  }) {
    // If already showing, don't duplicate
    if (_currentEntry != null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    HapticFeedback.lightImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _UpdateBannerWidget(
        release: release,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        onDismiss: () {
          _dismiss();
        },
        onTapUpdate: () {
          _dismiss();
          AppUpdateSheet.show(
            context,
            release: release,
            currentVersion: currentVersion,
            currentBuild: currentBuild,
          );
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // Auto-dismiss after 5 seconds
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _dismiss();
    });
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }
}

class _UpdateBannerWidget extends StatefulWidget {
  final AppReleaseInfo release;
  final String currentVersion;
  final String currentBuild;
  final VoidCallback onDismiss;
  final VoidCallback onTapUpdate;

  const _UpdateBannerWidget({
    required this.release,
    required this.currentVersion,
    required this.currentBuild,
    required this.onDismiss,
    required this.onTapUpdate,
  });

  @override
  State<_UpdateBannerWidget> createState() => _UpdateBannerWidgetState();
}

class _UpdateBannerWidgetState extends State<_UpdateBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      top: mediaQuery.padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTapUpdate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.burgundy, Color(0xFF5A1E2E)],
                ),
                borderRadius: AppRadius.borderCard,
                border: Border.all(color: AppColors.dustyRose, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.burgundy.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.paper.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFDFB15B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Update Available: v${widget.release.version}',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.paper,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Tap to download & install update 💕',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.blushSand,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dustyRose,
                      borderRadius: AppRadius.borderPill,
                    ),
                    child: Text(
                      'Update',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.espresso,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.blushSand,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _handleDismiss,
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
