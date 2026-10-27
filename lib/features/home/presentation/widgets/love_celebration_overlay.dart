import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/romantic_audio_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Helper to trigger spectacular romantic love animations anywhere in the app
/// (e.g., hold button completion, live partner love event, or notification opening).
abstract final class LoveCelebrationOverlay {
  /// Shows the grand +1,000 Mega Love Shower explosion with 28 physics particle hearts & sparkles,
  /// soft ambient glow, glowing floating banner, haptics, and automatically plays [assets/music.mp3] melody.
  static void showMegaShower(
    BuildContext context, {
    Offset? center,
    String partnerName = 'Your Partner',
    int count = 1000,
    bool playMelody = true,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final mediaQuery = MediaQuery.of(context);
    final targetCenter =
        center ??
        Offset(mediaQuery.size.width / 2, mediaQuery.size.height * 0.42);

    // 1. Play romantic melody on both sides
    if (playMelody) {
      RomanticAudioPlayer.instance.playRomanticMelody();
    }

    // 2. Celebratory haptic rhythm: lub-dub pulse then heavy impact
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      HapticFeedback.mediumImpact();
    });

    // 3. Mount explosion overlay
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => MegaShowerExplosionWidget(
        center: targetCenter,
        partnerName: partnerName,
        count: count,
        onComplete: () {
          try {
            entry.remove();
          } catch (_) {}
        },
      ),
    );

    overlay.insert(entry);
  }

  /// Shows a floating love heart with mini +1 badge on tap.
  static void showSingleHeart(BuildContext context, {Offset? center}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final mediaQuery = MediaQuery.of(context);
    final targetCenter =
        center ??
        Offset(mediaQuery.size.width / 2, mediaQuery.size.height * 0.48);

    HapticFeedback.lightImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => SingleHeartFloatWidget(
        center: targetCenter,
        onComplete: () {
          try {
            entry.remove();
          } catch (_) {}
        },
      ),
    );

    overlay.insert(entry);
  }
}

/// Floating mini heart with +1 badge animation widget.
class SingleHeartFloatWidget extends StatefulWidget {
  final Offset center;
  final VoidCallback onComplete;

  const SingleHeartFloatWidget({
    super.key,
    required this.center,
    required this.onComplete,
  });

  @override
  State<SingleHeartFloatWidget> createState() => _SingleHeartFloatWidgetState();
}

class _SingleHeartFloatWidgetState extends State<SingleHeartFloatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final dy = -85 * Curves.easeOutCubic.transform(progress);
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          final scale = 0.85 + 0.45 * sin(progress * pi);

          return Positioned(
            left: widget.center.dx - 28,
            top: widget.center.dy + dy - 20,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.dustyRose,
                      size: 26,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.burgundy,
                        borderRadius: AppRadius.borderPill,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.burgundy.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '+1 💕',
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Spectacular +1,000 celebration overlay with 28 expanding particle hearts & sparkles,
/// ambient romantic glow, and a floating love banner.
class MegaShowerExplosionWidget extends StatefulWidget {
  final Offset center;
  final String partnerName;
  final int count;
  final VoidCallback onComplete;

  const MegaShowerExplosionWidget({
    super.key,
    required this.center,
    required this.partnerName,
    this.count = 1000,
    required this.onComplete,
  });

  @override
  State<MegaShowerExplosionWidget> createState() =>
      _MegaShowerExplosionWidgetState();
}

class _MegaShowerExplosionWidgetState extends State<MegaShowerExplosionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ParticleItem> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();

    const romanticColors = [
      AppColors.burgundy,
      AppColors.dustyRose,
      Color(0xFFE88B97),
      Color(0xFFF4A8B3),
      Color(0xFFDFB15B), // Golden sparkle
    ];

    // 28 physics-based particles erupting outward
    for (int i = 0; i < 28; i++) {
      final angle = (i * (2 * pi / 28)) + (_rnd.nextDouble() * 0.4 - 0.2);
      final distance = 75.0 + _rnd.nextDouble() * 115.0;
      final size = 14.0 + _rnd.nextDouble() * 18.0;
      final color = romanticColors[i % romanticColors.length];
      final isSparkle = i % 4 == 0;
      final rotation = (_rnd.nextDouble() * 2 - 1) * pi;

      _particles.add(
        _ParticleItem(
          angle: angle,
          distance: distance,
          size: size,
          color: color,
          isSparkle: isSparkle,
          rotation: rotation,
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final outCurve = Curves.easeOutCubic.transform(t);

          // Ambient glow pulse
          final ambientGlowOpacity = (sin(t * pi) * 0.35).clamp(0.0, 1.0);

          // Pop pill badge animation with subtle bounce
          final pillScale = t < 0.22
              ? Curves.easeOutBack.transform(t / 0.22) * 1.08
              : (1.08 - 0.08 * ((t - 0.22) / 0.78));
          final pillY = -75 * outCurve;
          final pillOpacity = t < 0.78
              ? 1.0
              : ((1.0 - t) / 0.22).clamp(0.0, 1.0);

          final countText = widget.count >= 1000
              ? '+${widget.count.toString()} LOVE SHOWER'
              : '+${widget.count} LOVE';

          return Stack(
            children: [
              // 0. Ambient Soft Rose Glow Halo
              Positioned(
                left: widget.center.dx - 160,
                top: widget.center.dy + pillY - 100,
                child: Opacity(
                  opacity: ambientGlowOpacity,
                  child: Container(
                    width: 320,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.dustyRose.withValues(alpha: 0.4),
                          const Color(0xFFDFB15B).withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 1. Erupting Particle Hearts & Sparkles
              ..._particles.map((p) {
                final dx = cos(p.angle) * p.distance * outCurve;
                final dy =
                    sin(p.angle) * p.distance * outCurve - (85 * outCurve);
                final particleOpacity = (1.0 - t).clamp(0.0, 1.0);
                final particleScale = (1.0 - 0.25 * t);

                return Positioned(
                  left: widget.center.dx + dx - (p.size / 2),
                  top: widget.center.dy + dy - (p.size / 2),
                  child: Opacity(
                    opacity: particleOpacity,
                    child: Transform.rotate(
                      angle: p.rotation * t,
                      child: Transform.scale(
                        scale: particleScale,
                        child: Icon(
                          p.isSparkle
                              ? Icons.auto_awesome_rounded
                              : Icons.favorite_rounded,
                          size: p.size,
                          color: p.color,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // 2. Center Floating Grand Celebration Card
              Positioned(
                left: widget.center.dx - 115,
                top: widget.center.dy + pillY - 32,
                child: Opacity(
                  opacity: pillOpacity,
                  child: Transform.scale(
                    scale: pillScale,
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.burgundy, Color(0xFF5A1E2E)],
                        ),
                        borderRadius: AppRadius.borderCard,
                        border: Border.all(
                          color: AppColors.dustyRose,
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.burgundy.withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFFDFB15B,
                            ).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.dustyRose,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  countText,
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.paper,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.6,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFDFB15B),
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'with love from ${widget.partnerName} 💕',
                            style: AppTypography.handwrittenCaption.copyWith(
                              color: AppColors.blushSand,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParticleItem {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final bool isSparkle;
  final double rotation;

  const _ParticleItem({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    this.isSparkle = false,
    this.rotation = 0.0,
  });
}
