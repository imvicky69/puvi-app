import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Quick interactive romantic action tiles right beneath the hero card.
class QuickLoveActions extends StatelessWidget {
  final VoidCallback onSendLove;
  final VoidCallback onOpenNote;
  final int loveCount;

  const QuickLoveActions({
    super.key,
    required this.onSendLove,
    required this.onOpenNote,
    this.loveCount = 272000,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Send Love Ping Action
        Expanded(
          child: _ActionTile(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.dustyRose,
            title: 'Send Love',
            subtitle: '${(loveCount / 1000).toStringAsFixed(1)}k sent',
            onTap: onSendLove,
          ),
        ),

        AppSpacing.horizontalSm,

        // 2. Secret Love Whisper / Note Action
        Expanded(
          child: _ActionTile(
            icon: Icons.mark_email_unread_outlined,
            iconColor: AppColors.burgundy,
            title: 'Love Whisper',
            subtitle: 'Open note',
            onTap: onOpenNote,
          ),
        ),

        AppSpacing.horizontalSm,

        // 3. Days Count Milestone Tile
        Expanded(
          child: _ActionTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.burgundy,
            title: 'Next Chapter',
            subtitle: 'Apr 11, 2026',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Anniversary milestone coming on April 11, 2026! 💍✨',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderCard,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: AppRadius.borderCard,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.espresso,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.taupe,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
