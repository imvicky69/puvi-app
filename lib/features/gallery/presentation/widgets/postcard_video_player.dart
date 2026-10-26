import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive in-app video player for memory clips.
///
/// Features:
/// - Auto-play on open with loop support.
/// - Tap anywhere to toggle Play/Pause.
/// - Visual progress indicator scrub bar.
/// - Mute / Unmute audio toggle.
/// - Defensive fallback if native ExoPlayer binary is pending restart.
class PostcardVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double fallbackAspectRatio;

  const PostcardVideoPlayer({
    super.key,
    required this.videoUrl,
    this.fallbackAspectRatio = 0.75,
  });

  @override
  State<PostcardVideoPlayer> createState() => _PostcardVideoPlayerState();
}

class _PostcardVideoPlayerState extends State<PostcardVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      if (!mounted) return;

      _controller!.setLooping(true);
      await _controller!.play();

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallbackView();
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingView();
    }

    final isPlaying = _controller!.value.isPlaying;
    final aspect = _controller!.value.aspectRatio > 0
        ? _controller!.value.aspectRatio
        : widget.fallbackAspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: aspect.clamp(0.56, 1.4),
        child: GestureDetector(
          onTap: _togglePlayPause,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Raw Video Stream
              VideoPlayer(_controller!),

              // 2. Play/Pause overlay icon when paused
              if (!isPlaying)
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),

              // 3. Top-Right Mute/Unmute Toggle
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),

              // 4. Bottom Video Progress Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.burgundy,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.black26,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return AspectRatio(
      aspectRatio: widget.fallbackAspectRatio.clamp(0.6, 1.3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.espresso,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.dustyRose,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Buffering clip...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackView() {
    return AspectRatio(
      aspectRatio: widget.fallbackAspectRatio.clamp(0.6, 1.3),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.espresso,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.dustyRose,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Video Clip Memory',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hot restart (R) to enable native player',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _initPlayer,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Retry Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
