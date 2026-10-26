import 'package:flutter/material.dart';
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
  int _loveCount = 272000;

  void _sendLovePing() {
    setState(() => _loveCount++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.favorite, color: AppColors.dustyRose, size: 18),
            SizedBox(width: 8),
            Text('Love Ping sent to your partner! 💕'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.espresso,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSecretLoveNote() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AppSpacing.verticalMd,
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.blushSand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 28,
                      color: AppColors.burgundy,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    'Today\'s Love Note',
                    style: AppTypography.h2.copyWith(
                      fontSize: 20,
                      color: AppColors.espresso,
                    ),
                  ),
                  AppSpacing.verticalXs,
                  Text(
                    '"I loved you yesterday, I love you still, I always have, I always will."\n— For Vicky & Puja',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: AppColors.espresso,
                      height: 1.4,
                    ),
                  ),
                  AppSpacing.verticalMd,
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close Whisper'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                          onLoveCountChanged: (count) {
                            setState(() => _loveCount = count);
                          },
                        ),

                        AppSpacing.verticalMd,

                        // Quick Romantic Action Tiles
                        QuickLoveActions(
                          loveCount: _loveCount,
                          onSendLove: _sendLovePing,
                          onOpenNote: _openSecretLoveNote,
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
