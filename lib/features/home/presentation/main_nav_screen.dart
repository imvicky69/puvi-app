import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/services/fcm_token_service.dart';
import '../../../core/services/love_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../account/presentation/account_tab.dart';
import '../../gallery/presentation/gallery_tab.dart';
import '../../timeline/presentation/timeline_tab.dart';
import 'home_tab.dart';
import 'widgets/app_update_banner.dart';
import 'widgets/love_celebration_overlay.dart';
import 'widgets/puvi_bottom_nav_bar.dart';

/// Main navigation shell holding the bottom navigation bar and active tab views.
/// Also hosts the global real-time partner love listener and push notification handler.
class MainNavScreen extends StatefulWidget {
  final String userName;
  final int initialIndex;

  const MainNavScreen({
    super.key,
    this.userName = 'Vicky',
    this.initialIndex = 0,
  });

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;
  StreamSubscription<LoveUpdateEvent>? _partnerLoveSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // 1. Establish current active user for love sync & partner identification
    LoveStatsService.setCurrentUser(widget.userName);

    // 2. Initialize push notification handling (tapping & foreground messages)
    FcmTokenService.initializeNotificationHandling();

    // 3. Listen for real-time love shower events from the partner or push notifications
    _partnerLoveSub = LoveStatsService.onPartnerLove.listen((event) {
      if (!mounted) return;

      if (event.isMegaShower || event.increment >= 1000) {
        // Grand celebration overlay + melody on both sides
        LoveCelebrationOverlay.showMegaShower(
          context,
          partnerName: event.senderName,
          count: event.increment,
          playMelody: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.dustyRose,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✨ ${event.senderName} showered you with +${event.increment.toString()} Love Pings! 💕',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.espresso,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Delicate single heart tap animation
        LoveCelebrationOverlay.showSingleHeart(context);
      }
    });

    // 4. Background update check: displays 5-second top banner if newer GitHub release exists
    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) {
      _updateCheckTimer = Timer(const Duration(seconds: 3), () async {
        if (!mounted) return;
        final update = await AppUpdateService.checkForUpdate();
        if (mounted && update != null) {
          final pkg = await AppUpdateService.getPackageInfo();
          if (mounted) {
            AppUpdateBanner.show(
              context,
              release: update,
              currentVersion: pkg.version,
              currentBuild: pkg.buildNumber,
            );
          }
        }
      });
    }
  }

  Timer? _updateCheckTimer;

  @override
  void dispose() {
    _updateCheckTimer?.cancel();
    _partnerLoveSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(userName: widget.userName),
          TimelineTab(userName: widget.userName),
          const GalleryTab(),
          AccountTab(userName: widget.userName),
        ],
      ),
      bottomNavigationBar: PuviBottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
