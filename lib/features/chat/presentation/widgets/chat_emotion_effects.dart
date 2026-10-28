import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/chat_message.dart';

/// Full-screen overlay particle engine delivering dramatic effects
/// for Kiss (💋), Hug (🤗), Knife / Angry (🔪), and Flower (🌸).
class ChatEmotionEffects extends StatefulWidget {
  final String emotionType;
  final VoidCallback onDismiss;

  const ChatEmotionEffects({
    super.key,
    required this.emotionType,
    required this.onDismiss,
  });

  @override
  State<ChatEmotionEffects> createState() => _ChatEmotionEffectsState();
}

class _ChatEmotionEffectsState extends State<ChatEmotionEffects>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _initParticles();
    _triggerHaptics();

    _controller.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _triggerHaptics() {
    switch (widget.emotionType) {
      case ChatMessageType.knife:
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 120), () {
          HapticFeedback.heavyImpact();
        });
        break;
      case ChatMessageType.kiss:
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          HapticFeedback.lightImpact();
        });
        break;
      case ChatMessageType.hug:
        HapticFeedback.mediumImpact();
        break;
      case ChatMessageType.flower:
        HapticFeedback.lightImpact();
        break;
    }
  }

  void _initParticles() {
    final count = widget.emotionType == ChatMessageType.flower ? 32 : 24;
    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: widget.emotionType == ChatMessageType.flower
              ? -0.2 - (_random.nextDouble() * 0.4)
              : 0.5 + (_random.nextDouble() * 0.2 - 0.1),
          speedX: (_random.nextDouble() - 0.5) * 0.8,
          speedY: widget.emotionType == ChatMessageType.flower
              ? 0.4 + (_random.nextDouble() * 0.6)
              : -0.5 - (_random.nextDouble() * 0.8),
          size: 16.0 + _random.nextDouble() * 22.0,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 4.0,
          emoji: _getParticleEmoji(i),
        ),
      );
    }
  }

  String _getParticleEmoji(int index) {
    switch (widget.emotionType) {
      case ChatMessageType.kiss:
        const kissEmojis = ['💋', '💖', '💕', '✨', '😘', '❤️'];
        return kissEmojis[index % kissEmojis.length];
      case ChatMessageType.hug:
        const hugEmojis = ['🤗', '🫂', '💛', '✨', '🧸', '🥰'];
        return hugEmojis[index % hugEmojis.length];
      case ChatMessageType.knife:
        const angryEmojis = ['🔪', '⚡', '💢', '😡', '😤', '💥'];
        return angryEmojis[index % angryEmojis.length];
      case ChatMessageType.flower:
      default:
        const flowerEmojis = ['🌸', '🌺', '🌹', '🌷', '✨', '💐'];
        return flowerEmojis[index % flowerEmojis.length];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _bannerTitle {
    switch (widget.emotionType) {
      case ChatMessageType.kiss:
        return '💋 Sweet Romantic Kiss!';
      case ChatMessageType.hug:
        return '🤗 Warm Cozy Embrace!';
      case ChatMessageType.knife:
        return '🔪 Angry Dramatic Pout!';
      case ChatMessageType.flower:
      default:
        return '🌸 Fresh Romantic Blossoms!';
    }
  }

  String get _bannerSubtitle {
    switch (widget.emotionType) {
      case ChatMessageType.kiss:
        return 'A gentle mwah showered on your heart 💕';
      case ChatMessageType.hug:
        return 'Holding you close in a tight cuddle 💕';
      case ChatMessageType.knife:
        return 'Beware! Handle immediately with hugs and kisses 🥺';
      case ChatMessageType.flower:
      default:
        return 'Drifting fresh petals just for you 💕';
    }
  }

  Color get _glowColor {
    switch (widget.emotionType) {
      case ChatMessageType.kiss:
        return AppColors.dustyRose.withValues(alpha: 0.22);
      case ChatMessageType.hug:
        return const Color(0xFFE5B978).withValues(alpha: 0.20);
      case ChatMessageType.knife:
        return AppColors.error.withValues(alpha: 0.18);
      case ChatMessageType.flower:
      default:
        return AppColors.dustyRose.withValues(alpha: 0.18);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          // Fade in fast, hold, then fade out
          final double opacity = progress < 0.15
              ? (progress / 0.15)
              : (progress > 0.8 ? ((1.0 - progress) / 0.2) : 1.0);

          // Screen shake for knife/angry
          double shakeX = 0;
          double shakeY = 0;
          if (widget.emotionType == ChatMessageType.knife && progress < 0.4) {
            final t = progress * 20;
            shakeX = math.sin(t * math.pi) * 6 * (1.0 - progress / 0.4);
            shakeY = math.cos(t * math.pi * 0.8) * 4 * (1.0 - progress / 0.4);
          }

          return Transform.translate(
            offset: Offset(shakeX, shakeY),
            child: Container(
              color: _glowColor.withValues(
                alpha: _glowColor.a * opacity.clamp(0.0, 1.0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Dynamic Floating Particles
                  CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: progress,
                      opacity: opacity.clamp(0.0, 1.0),
                    ),
                  ),

                  // 2. Central Dramatic Hero Element
                  Center(
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCenterHero(progress),
                          AppSpacing.verticalMd,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: AppRadius.borderPill,
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.espresso.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _bannerTitle,
                                  style: AppTypography.h3.copyWith(
                                    fontSize: 18,
                                    color: AppColors.espresso,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _bannerSubtitle,
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.taupe,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCenterHero(double progress) {
    final scale = progress < 0.2
        ? (progress / 0.2) * 1.3
        : 1.3 - ((progress - 0.2) * 0.3).clamp(0.0, 0.3);

    String emoji;
    switch (widget.emotionType) {
      case ChatMessageType.kiss:
        emoji = '💋';
        break;
      case ChatMessageType.hug:
        emoji = '🤗';
        break;
      case ChatMessageType.knife:
        emoji = '🔪';
        break;
      case ChatMessageType.flower:
      default:
        emoji = '🌸';
        break;
    }

    return Transform.scale(
      scale: scale,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 88, decoration: TextDecoration.none),
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  final double speedX;
  final double speedY;
  final double size;
  double rotation;
  final double rotationSpeed;
  final String emoji;

  _Particle({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.emoji,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double opacity;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final p in particles) {
      final currentX =
          (p.x * size.width) +
          (p.speedX * progress * size.width * 0.4) +
          math.sin(progress * 8 + p.rotation) * 20;
      final currentY =
          (p.y * size.height) + (p.speedY * progress * size.height * 0.8);
      final currentRot = p.rotation + (p.rotationSpeed * progress);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);

      textPainter.text = TextSpan(
        text: p.emoji,
        style: TextStyle(
          fontSize: p.size,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
