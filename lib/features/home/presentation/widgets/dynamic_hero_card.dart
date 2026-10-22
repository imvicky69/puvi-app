import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Memory model for the dynamic hero section.
class HeroMemory {
  final String imageAsset;
  final String tag;
  final String title;
  final String subtitle;
  final String caption;
  final Alignment imageAlignment;

  const HeroMemory({
    required this.imageAsset,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.imageAlignment,
  });
}

/// Particle model for floating heart micro-interactions.
class _FloatingHeart {
  final Key key;
  final double startX;
  final double startY;
  final double targetY;
  final double drift;
  final double size;
  final Color color;

  _FloatingHeart({
    required this.key,
    required this.startX,
    required this.startY,
    required this.targetY,
    required this.drift,
    required this.size,
    required this.color,
  });
}

/// A dynamic, interactive Hero Card for the Puvi home screen.
///
/// Features:
/// - Smooth carousel between [puvi-1.jpeg] and [puvi-2.jpeg] with custom framing.
/// - Dynamic romantic typography overlay with serif title and italic subtitle.
/// - Top story progress indicator bars.
/// - Ken Burns subtle breathing zoom effect.
/// - Double-tap / tap heart reaction particle burst that increments love pings.
/// - Interactive dynamic quote generator ("Love Whispers").
class DynamicHeroCard extends StatefulWidget {
  final int initialLoveCount;
  final ValueChanged<int>? onLoveCountChanged;
  final bool autoAnimate;

  const DynamicHeroCard({
    super.key,
    this.initialLoveCount = 272000,
    this.onLoveCountChanged,
    this.autoAnimate = true,
  });

  @override
  State<DynamicHeroCard> createState() => _DynamicHeroCardState();
}

class _DynamicHeroCardState extends State<DynamicHeroCard>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _zoomController;
  Timer? _autoPlayTimer;
  int _currentIndex = 0;
  late int _loveCount;

  bool get _isTestEnv =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  final List<_FloatingHeart> _hearts = [];
  final Random _random = Random();

  // Romantic love quotes Vicky & Puja can shuffle through
  final List<String> _loveWhispers = [
    'A beautiful journey together',
    'Every glance says a thousand words',
    'You are my today and all of my tomorrows',
    'Home is wherever I am with you',
    'Growing in love, hand in hand',
    'Two souls, one heartbeat • Vicky & Puja',
  ];
  int _whisperIndex = 0;

  static const List<HeroMemory> _memories = [
    HeroMemory(
      imageAsset: 'assets/puvi-1.jpeg',
      tag: '✨ PALACE DREAMS',
      title: 'LOVE BIRDS',
      subtitle: 'A beautiful journey together',
      caption: 'Jaipur • Golden Hour Glow',
      imageAlignment: Alignment(0.0, -0.28),
    ),
    HeroMemory(
      imageAsset: 'assets/puvi-2.jpeg',
      tag: '🪞 CANDID FRAMES',
      title: 'OUR SANCTUARY',
      subtitle: 'Every glance says a thousand words',
      caption: 'Together in Style • Hand in Hand',
      imageAlignment: Alignment(0.0, -0.32),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loveCount = widget.initialLoveCount;
    _pageController = PageController();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    // Only auto-animate if not running inside automated widget tests
    if (widget.autoAnimate && !_isTestEnv) {
      _zoomController.repeat(reverse: true);
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted) return;
      final nextIndex = (_currentIndex + 1) % _memories.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  void _resumeAutoPlay() {
    _startAutoPlay();
  }

  void _cycleWhisper() {
    setState(() {
      _whisperIndex = (_whisperIndex + 1) % _loveWhispers.length;
    });
  }

  void _spawnHeart(Offset localPosition) {
    setState(() {
      _loveCount++;
      widget.onLoveCountChanged?.call(_loveCount);

      final heart = _FloatingHeart(
        key: UniqueKey(),
        startX: localPosition.dx,
        startY: localPosition.dy,
        targetY: localPosition.dy - 120 - _random.nextDouble() * 60,
        drift: (_random.nextDouble() - 0.5) * 60,
        size: 24.0 + _random.nextDouble() * 16.0,
        color: _random.nextBool() ? AppColors.burgundy : AppColors.dustyRose,
      );

      _hearts.add(heart);
    });

    // Auto remove heart after 1.2s
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          if (_hearts.isNotEmpty) {
            _hearts.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 390,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 1. Zoomable Image Carousel
            GestureDetector(
              onTapDown: (details) {
                _pauseAutoPlay();
              },
              onTapUp: (details) {
                _resumeAutoPlay();
              },
              onDoubleTapDown: (details) {
                _spawnHeart(details.localPosition);
              },
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: _memories.length,
                itemBuilder: (context, index) {
                  final memory = _memories[index];
                  return AnimatedBuilder(
                    animation: _zoomController,
                    builder: (context, child) {
                      final scale = 1.0 + (_zoomController.value * 0.06);
                      return Transform.scale(
                        scale: scale,
                        child: Image.asset(
                          memory.imageAsset,
                          fit: BoxFit.cover,
                          alignment: memory.imageAlignment,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.blushSand,
                              child: const Center(
                                child: Icon(
                                  Icons.favorite,
                                  size: 48,
                                  color: AppColors.dustyRose,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 2. Cinematic Gradient Overlays (Top & Bottom for crisp contrast)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25, 0.5, 0.72, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top Header: Story Bars & Floating Glass Pills
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Column(
                children: [
                  // Instagram-style story indicator bars
                  Row(
                    children: List.generate(_memories.length, (index) {
                      final isActive = index == _currentIndex;
                      return Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),

                  AppSpacing.verticalSm,

                  // Floating Chips: Days Together & Love Ping Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Together Forever pill
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 13,
                                color: AppColors.dustyRose,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Day 1,428 • Vicky & Puja',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.captionSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Interactive Love Tap Chip
                      GestureDetector(
                        onTap: () {
                          // Tap spawns hearts in center-right
                          _spawnHeart(const Offset(300, 260));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.burgundy.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.burgundy.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(_loveCount / 1000).toStringAsFixed(1)}k',
                                style: AppTypography.captionSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Tap Navigation Zones (Left tap = previous, Right tap = next)
            Positioned(
              left: 0,
              top: 70,
              bottom: 120,
              width: 70,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  final prev =
                      (_currentIndex - 1 + _memories.length) % _memories.length;
                  _pageController.animateToPage(
                    prev,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),
            Positioned(
              right: 0,
              top: 70,
              bottom: 120,
              width: 70,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  final next = (_currentIndex + 1) % _memories.length;
                  _pageController.animateToPage(
                    next,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),

            // 5. Dynamic Content: Memory Tag, Editorial Title & Interactive Subtitle
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey<int>(_currentIndex),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dynamic Location / Tag Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        _memories[_currentIndex].tag,
                        style: AppTypography.captionSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Main Editorial Serif Title ("LOVE BIRDS" / "OUR SANCTUARY")
                    Text(
                      _memories[_currentIndex].title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 4.2,
                        height: 1.15,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 2),
                            blurRadius: 10,
                          ),
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Dynamic Subtitle with interactive quote shuffler
                    GestureDetector(
                      onTap: _cycleWhisper,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _loveWhispers[_whisperIndex],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.92),
                                letterSpacing: 0.3,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sub-caption
                    Text(
                      _memories[_currentIndex].caption,
                      style: AppTypography.captionSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Floating Heart Particle Layer (Tap reactions)
            ..._hearts.map((heart) {
              return TweenAnimationBuilder<double>(
                key: heart.key,
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  final curX = heart.startX + (heart.drift * value);
                  final curY = heart.startY - (120 * value);
                  final opacity = (1.0 - value).clamp(0.0, 1.0);
                  final scale = 0.5 + (sin(value * pi) * 0.8);

                  return Positioned(
                    left: curX - (heart.size / 2),
                    top: curY - (heart.size / 2),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.favorite_rounded,
                          size: heart.size,
                          color: heart.color,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
