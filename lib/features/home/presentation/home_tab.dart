import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/love_stats_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/dynamic_hero_card.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_love_actions.dart';

/// The Home tab view featuring the top clean-logo header,
/// the dynamic couple hero card, and interactive love actions.
class HomeTab extends StatefulWidget {
  final String userName;

  const HomeTab({super.key, this.userName = 'Vicky'});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _loveCount = LoveStatsService.currentLoveCount;
  StreamSubscription<int>? _statsSub;

  @override
  void initState() {
    super.initState();
    _statsSub = LoveStatsService.watchLoveCount().listen((count) {
      if (mounted && count != _loveCount) {
        setState(() => _loveCount = count);
      }
    });
  }

  @override
  void dispose() {
    _statsSub?.cancel();
    super.dispose();
  }

  void _sendLovePing([int increment = 1]) {
    // 1. Instant optimistic UI feedback
    setState(() => _loveCount += increment);

    // 2. Atomically persist to Firestore `shared/stats` and record in `pings`
    LoveStatsService.incrementLove(
      userName: widget.userName,
      increment: increment,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: AppColors.dustyRose, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                increment > 1
                    ? '✨ Mega Love Shower! +$increment pings showered with melody 💕'
                    : 'Love Ping sent to your partner! 💕',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.espresso,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Component (clean logo without box padding)
            HomeHeader(userName: widget.userName),

            const Divider(),

            // 2. Scrollable Home Dashboard
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dynamic Hero Section with Vicky & Puja's photos
                        DynamicHeroCard(
                          initialLoveCount: _loveCount,
                          togetherSince: LoveStatsService.togetherSince,
                          onLoveCountChanged: (count) {
                            final diff = count - _loveCount;
                            if (diff > 0) {
                              _sendLovePing(diff);
                            }
                          },
                        ),

                        AppSpacing.verticalMd,

                        // Quick Romantic Action Tiles
                        QuickLoveActions(
                          loveCount: _loveCount,
                          partnerName: widget.userName.toLowerCase() == 'puja'
                              ? 'Vicky'
                              : 'Puja',
                          togetherSince: LoveStatsService.togetherSince,
                          onSendLove: _sendLovePing,
                          onSendLoveBatch: (batch) => _sendLovePing(batch),
                        ),

                        AppSpacing.verticalLg,

                        // Daily Couple Affirmation & Status
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: AppRadius.borderCard,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.espresso.withValues(
                                  alpha: 0.02,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: AppColors.blushSand,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 20,
                                  color: AppColors.dustyRose,
                                ),
                              ),
                              AppSpacing.horizontalMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Together Forever',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.espresso,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Every moment is a memory in the making.',
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color: AppColors.taupe,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blushSand,
                                  borderRadius: AppRadius.borderPill,
                                ),
                                child: Text(
                                  'In Sync',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.burgundy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        AppSpacing.verticalLg,

                        // Editorial Brand Tag
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: AppRadius.borderPill,
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Puvi • Love Letters',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.burgundy,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        AppSpacing.verticalMd,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
