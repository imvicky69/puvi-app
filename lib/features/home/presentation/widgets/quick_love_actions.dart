import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/love_stats_service.dart';
import '../../../../core/services/romantic_audio_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/anniversary_helper.dart';
import 'love_celebration_overlay.dart';

/// Quick interactive romantic action tiles right beneath the hero card.
///
/// Features:
/// - 2 wide, balanced action tiles: Alive "Send Love" on the left, "Next Chapter" on the right.
/// - Alive "Send Love" tile with heartbeat pulsing micro-animation and hold-for-1k shower.
/// - Alive "Next Chapter" tile tracking upcoming Monthly, Half-Yearly and Yearly anniversaries
///   with a live minimal countdown clock ticking down every second.
class QuickLoveActions extends StatefulWidget {
  final VoidCallback onSendLove;
  final ValueChanged<int>? onSendLoveBatch;
  final int loveCount;
  final String partnerName;
  final DateTime? togetherSince;

  const QuickLoveActions({
    super.key,
    required this.onSendLove,
    this.onSendLoveBatch,
    this.loveCount = 272000,
    this.partnerName = 'Puja',
    this.togetherSince,
  });

  @override
  State<QuickLoveActions> createState() => _QuickLoveActionsState();
}

class _QuickLoveActionsState extends State<QuickLoveActions> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Alive "Send Love" Action with Hold-to-Charge +1,000 & Melody
        Expanded(
          child: _AliveSendLoveTile(
            loveCount: widget.loveCount,
            partnerName: widget.partnerName,
            onSinglePing: widget.onSendLove,
            onMegaShower: (batch) {
              if (widget.onSendLoveBatch != null) {
                widget.onSendLoveBatch!(batch);
              } else {
                widget.onSendLove();
              }
            },
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // 2. Next Chapter Action Tile with live minimal countdown clock
        Expanded(
          child: _NextChapterTile(
            togetherSince:
                widget.togetherSince ?? LoveStatsService.togetherSince,
          ),
        ),
      ],
    );
  }
}

/// The living "Send Love" tile with heartbeat, charge ring, haptics,
/// audio playback, and +1,000 particle celebration.
class _AliveSendLoveTile extends StatefulWidget {
  final int loveCount;
  final String partnerName;
  final VoidCallback onSinglePing;
  final ValueChanged<int> onMegaShower;

  const _AliveSendLoveTile({
    required this.loveCount,
    required this.partnerName,
    required this.onSinglePing,
    required this.onMegaShower,
  });

  @override
  State<_AliveSendLoveTile> createState() => _AliveSendLoveTileState();
}

class _AliveSendLoveTileState extends State<_AliveSendLoveTile>
    with TickerProviderStateMixin {
  // Continuous heartbeat pulse controller
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatScale;

  // Hold-to-charge controller (1250ms hold)
  late AnimationController _chargeController;
  Timer? _hapticTimer;
  DateTime? _pressStartTime;
  bool _isCompleted = false;

  final GlobalKey _tileKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // 1. Natural rhythm heartbeat (lub-dub pulse)
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _heartbeatScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.20,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.20,
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.02,
          end: 1.14,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.14,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_heartbeatController);

    // 2. Charging controller (1.25s duration)
    _chargeController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1250),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && !_isCompleted) {
            _onHoldCompleted();
          }
        });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _heartbeatController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  void _onPressDown(TapDownDetails details) {
    _pressStartTime = DateTime.now();
    _isCompleted = false;

    // Initial light feedback
    HapticFeedback.lightImpact();

    // Start charging animation
    _chargeController.forward();

    // Progressive ticking haptics during charge
    _hapticTimer?.cancel();
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_chargeController.isAnimating) {
        HapticFeedback.selectionClick();
      } else {
        timer.cancel();
      }
    });
  }

  void _onPressUp(TapUpDetails details) {
    _hapticTimer?.cancel();

    if (_isCompleted) {
      // Hold was already triggered and completed
      _chargeController.reset();
      return;
    }

    final elapsed = DateTime.now().difference(
      _pressStartTime ?? DateTime.now(),
    );
    _chargeController.reverse();

    if (elapsed.inMilliseconds < 350) {
      // Quick tap: Send standard +1 Love Ping
      HapticFeedback.lightImpact();
      _spawnSingleHeartFloat();
      widget.onSinglePing();
    }
  }

  void _onPressCancel() {
    _hapticTimer?.cancel();
    if (!_isCompleted) {
      _chargeController.reverse();
    }
  }

  void _onHoldCompleted() {
    _isCompleted = true;
    _hapticTimer?.cancel();

    // 1. Celebratory heavy haptic burst
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });

    // 2. Play romantic background melody (music.mp3)
    RomanticAudioPlayer.instance.playRomanticMelody();

    // 3. Trigger +1,000 celebration overlay with bursting particle hearts
    _spawnMegaShowerCelebration();

    // 4. Increment love count by 1000
    widget.onMegaShower(1000);

    // 5. Smoothly reset charge controller
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _chargeController.reset();
        _isCompleted = false;
      }
    });
  }

  void _spawnSingleHeartFloat() {
    final renderBox = _tileKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? center;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      center = position + Offset(size.width / 2, size.height / 3);
    }
    LoveCelebrationOverlay.showSingleHeart(context, center: center);
  }

  void _spawnMegaShowerCelebration() {
    final renderBox = _tileKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? center;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      center = position + Offset(size.width / 2, size.height / 2);
    }
    LoveCelebrationOverlay.showMegaShower(
      context,
      center: center,
      partnerName: widget.partnerName,
      count: 1000,
      playMelody: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_heartbeatScale, _chargeController]),
      builder: (context, _) {
        final chargeProgress = _chargeController.value;
        final isCharging = chargeProgress > 0.05;
        final scale = 1.0 - (0.04 * chargeProgress);

        return Transform.scale(
          scale: scale,
          child: Material(
            key: _tileKey,
            color: Colors.transparent,
            child: GestureDetector(
              onTapDown: _onPressDown,
              onTapUp: _onPressUp,
              onTapCancel: _onPressCancel,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isCharging
                        ? [
                            AppColors.paper,
                            AppColors.dustyRose.withValues(alpha: 0.35),
                          ]
                        : [
                            AppColors.paper,
                            AppColors.blushSand.withValues(alpha: 0.3),
                          ],
                  ),
                  borderRadius: AppRadius.borderCard,
                  border: Border.all(
                    color: isCharging
                        ? AppColors.burgundy
                        : AppColors.dustyRose.withValues(alpha: 0.5),
                    width: isCharging ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCharging
                          ? AppColors.burgundy.withValues(alpha: 0.18)
                          : AppColors.espresso.withValues(alpha: 0.03),
                      blurRadius: isCharging ? 14 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Hint Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isCharging
                            ? AppColors.burgundy
                            : AppColors.blushSand.withValues(alpha: 0.8),
                        borderRadius: AppRadius.borderPill,
                      ),
                      child: Text(
                        isCharging ? 'Showering...' : 'Hold for 1k ✨',
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isCharging
                              ? AppColors.paper
                              : AppColors.burgundy,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Heart icon with breathing pulse and charging progress halo
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular charge progress ring
                          if (isCharging)
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: CircularProgressIndicator(
                                value: chargeProgress,
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.burgundy,
                                ),
                                backgroundColor: AppColors.dustyRose.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),

                          // Heart background disc
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isCharging
                                  ? AppColors.burgundy.withValues(alpha: 0.15)
                                  : AppColors.dustyRose.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                          ),

                          // Heartbeat pulse icon
                          Transform.scale(
                            scale: isCharging
                                ? (1.0 + 0.15 * sin(chargeProgress * pi * 8))
                                : _heartbeatScale.value,
                            child: Icon(
                              Icons.favorite_rounded,
                              size: 20,
                              color: isCharging
                                  ? AppColors.burgundy
                                  : AppColors.dustyRose,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Tile Title
                    Text(
                      'Send Love',
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 2),

                    // Subtitle with live counter
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          RomanticAudioPlayer.instance.isPlayingNotifier,
                      builder: (context, isMusicPlaying, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isMusicPlaying) ...[
                              const Icon(
                                Icons.music_note_rounded,
                                size: 10,
                                color: AppColors.burgundy,
                              ),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              '${(widget.loveCount / 1000).toStringAsFixed(1)}k sent',
                              style: AppTypography.captionSmall.copyWith(
                                color: isMusicPlaying
                                    ? AppColors.burgundy
                                    : AppColors.taupe,
                                fontWeight: isMusicPlaying
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Living "Next Chapter" action tile that tracks upcoming monthly,
/// half-yearly, and yearly anniversaries with an editorial minimal countdown clock.
class _NextChapterTile extends StatefulWidget {
  final DateTime togetherSince;

  const _NextChapterTile({required this.togetherSince});

  @override
  State<_NextChapterTile> createState() => _NextChapterTileState();
}

class _NextChapterTileState extends State<_NextChapterTile> {
  Timer? _ticker;
  int _activeMilestoneIndex = 0;

  @override
  void initState() {
    super.initState();
    // 1-second ticker for minimal live countdown clock
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  List<AnniversaryMilestone> get _milestones =>
      AnniversaryHelper.getUpcomingMilestones(widget.togetherSince);

  void _cycleNextMilestone() {
    HapticFeedback.selectionClick();
    setState(() {
      _activeMilestoneIndex = (_activeMilestoneIndex + 1) % _milestones.length;
    });
  }

  void _showAllMilestonesSheet(
    BuildContext context,
    List<AnniversaryMilestone> milestones,
  ) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                      Icons.auto_awesome_rounded,
                      size: 26,
                      color: AppColors.burgundy,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    'Our Upcoming Chapters',
                    style: AppTypography.h2.copyWith(
                      fontSize: 22,
                      color: AppColors.espresso,
                    ),
                  ),
                  AppSpacing.verticalXxs,
                  Text(
                    'Every milestone is another page of our forever story 💕',
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.taupe,
                    ),
                  ),
                  AppSpacing.verticalLg,
                  ...milestones.map((m) {
                    final isHighlighted =
                        milestones.indexOf(m) ==
                        (_activeMilestoneIndex % milestones.length);
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppColors.blushSand.withValues(alpha: 0.4)
                            : AppColors.ivory,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHighlighted
                              ? AppColors.burgundy
                              : AppColors.border,
                          width: isHighlighted ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              m.type == MilestoneType.yearly
                                  ? Icons.favorite_rounded
                                  : (m.type == MilestoneType.halfYearly
                                        ? Icons.diamond_rounded
                                        : Icons.cake_rounded),
                              size: 18,
                              color: AppColors.burgundy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m.badge,
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.burgundy,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      m.formattedDate(),
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.taupe,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.title,
                                  style: AppTypography.label.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.espresso,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m.formattedCountdown(),
                                  style: AppTypography.captionSmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.burgundy,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  AppSpacing.verticalMd,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cherish Forever'),
                    ),
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
    final milestones = _milestones;
    final active = milestones[_activeMilestoneIndex % milestones.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _cycleNextMilestone,
        onLongPress: () => _showAllMilestonesSheet(context, milestones),
        borderRadius: AppRadius.borderCard,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: AppRadius.borderCard,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top category badge pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blushSand.withValues(alpha: 0.5),
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(
                    color: AppColors.dustyRose.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 9,
                      color: AppColors.burgundy,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      active.badge,
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.burgundy,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Milestone icon in soft circle
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.blushSand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  active.type == MilestoneType.yearly
                      ? Icons.favorite_rounded
                      : (active.type == MilestoneType.halfYearly
                            ? Icons.diamond_rounded
                            : Icons.cake_rounded),
                  size: 20,
                  color: AppColors.burgundy,
                ),
              ),

              const SizedBox(height: 6),

              // Title: Next Chapter
              Text(
                'Next Chapter',
                style: AppTypography.captionSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.espresso,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 2),

              // Minimal live ticking countdown clock
              Text(
                active.formattedCountdown(),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 2),

              // Date e.g. "Nov 11, 2026"
              Text(
                active.formattedDate(),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.taupe,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Subtle indicator dots for milestone cycling
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(milestones.length, (i) {
                  final isCurrent =
                      i == (_activeMilestoneIndex % milestones.length);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: isCurrent ? 8 : 4,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.burgundy : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
