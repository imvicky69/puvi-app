import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Top header component for the Puvi home screen.
///
/// Features:
/// - Clean brand logo medallion.
/// - Dynamic time-of-day greeting ("Good morning / afternoon / evening").
/// - User's name in editorial typography.
/// - Interactive dummy chat icon with a subtle romantic notification indicator.
class HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback? onChatPressed;

  const HomeHeader({super.key, this.userName = 'Vicky', this.onChatPressed});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: AppColors.ivory,
      child: Row(
        children: [
          // Brand Logo Medallion
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espresso.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo_transparent.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/logo.png', fit: BoxFit.contain);
                },
              ),
            ),
          ),

          AppSpacing.horizontalMd,

          // Greeting & User Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.taupe,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h2.copyWith(
                          fontSize: 22,
                          color: AppColors.espresso,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    AppSpacing.horizontalXs,
                    const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: AppColors.dustyRose,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top-right dummy chat icon with subtle badge
          GestureDetector(
            onTap:
                onChatPressed ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat messages syncing soon 💕'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: AppRadius.borderButton,
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espresso.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.espresso,
                    size: 20,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.burgundy,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
