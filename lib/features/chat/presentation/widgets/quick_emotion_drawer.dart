import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/chat_message.dart';

/// Docked romantic affection action pills above the message composer.
class QuickEmotionDrawer extends StatelessWidget {
  final ValueChanged<String> onSelectEmotion;

  const QuickEmotionDrawer({super.key, required this.onSelectEmotion});

  @override
  Widget build(BuildContext context) {
    final emotions = [
      (
        type: ChatMessageType.kiss,
        emoji: '💋',
        label: 'Kiss',
        color: AppColors.dustyRose,
      ),
      (
        type: ChatMessageType.hug,
        emoji: '🤗',
        label: 'Hug',
        color: const Color(0xFFD49E58),
      ),
      (
        type: ChatMessageType.knife,
        emoji: '🔪',
        label: 'Angry',
        color: AppColors.error,
      ),
      (
        type: ChatMessageType.flower,
        emoji: '🌸',
        label: 'Flower',
        color: const Color(0xFFC77D88),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: emotions.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: AppColors.paper,
                borderRadius: AppRadius.borderPill,
                child: InkWell(
                  onTap: () => onSelectEmotion(item.type),
                  borderRadius: AppRadius.borderPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderPill,
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 5),
                        Text(
                          item.label,
                          style: AppTypography.label.copyWith(
                            fontSize: 12,
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
