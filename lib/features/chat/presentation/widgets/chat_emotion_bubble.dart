import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/chat_message.dart';

/// Postcard stamp card for romantic emotions (Kiss, Hug, Knife, Flower).
/// Includes a "Tap to replay ✨" trigger that re-fires the dramatic full-screen effect.
class ChatEmotionBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String partnerName;
  final VoidCallback onReplay;
  final VoidCallback? onLongPress;

  const ChatEmotionBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.partnerName,
    required this.onReplay,
    this.onLongPress,
  });

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Color get _accentColor {
    switch (message.type) {
      case ChatMessageType.kiss:
        return AppColors.dustyRose;
      case ChatMessageType.hug:
        return const Color(0xFFD49E58);
      case ChatMessageType.knife:
        return AppColors.error;
      case ChatMessageType.flower:
      default:
        return const Color(0xFFC77D88);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isMe ? AppColors.blushSand : AppColors.paper,
            borderRadius: AppRadius.borderCard,
            border: Border.all(
              color: isMe
                  ? AppColors.border
                  : _accentColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.borderCard,
            child: InkWell(
              onTap: onReplay,
              onLongPress: onLongPress,
              borderRadius: AppRadius.borderCard,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Emotion Icon + Title
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            message.emotionEmoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        AppSpacing.horizontalSm,
                        Flexible(
                          child: Text(
                            message.emotionTitle(
                              isMe: isMe,
                              partnerName: partnerName,
                            ),
                            style: AppTypography.label.copyWith(
                              fontSize: 14,
                              color: AppColors.espresso,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Optional Note text if attached
                    if (message.text.isNotEmpty) ...[
                      AppSpacing.verticalXs,
                      Text(
                        message.text,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.espresso,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    AppSpacing.verticalSm,

                    // Replay Pill Trigger & Timestamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.12),
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 12,
                                color: _accentColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Replay effect ✨',
                                style: AppTypography.captionSmall.copyWith(
                                  color: _accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.horizontalSm,
                        Text(
                          _formatTime(message.createdAt),
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.taupe.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isSeen
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 13,
                            color: message.isSeen
                                ? AppColors.burgundy
                                : AppColors.taupe.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
