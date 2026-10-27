import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart' show ValueNotifier, WidgetsBinding;

/// Romantic background music and sound player for Puja & Vicky.
///
/// Handles playing [assets/music.mp3] safely across devices and in test environments.
class RomanticAudioPlayer {
  static final RomanticAudioPlayer instance = RomanticAudioPlayer._internal();
  RomanticAudioPlayer._internal();

  AudioPlayer? _player;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  bool get isPlaying => isPlayingNotifier.value;

  /// Plays [assets/music.mp3] at volume [volume].
  Future<void> playRomanticMelody({double volume = 0.9}) async {
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (isTesting) return;

    try {
      _player ??= AudioPlayer();
      _player!.onPlayerStateChanged.listen((state) {
        isPlayingNotifier.value = state == PlayerState.playing;
      });

      // Stop previous instance if already playing to restart cleanly
      await _player!.stop();
      await _player!.setVolume(volume);
      await _player!.play(AssetSource('music.mp3'));
      isPlayingNotifier.value = true;
    } catch (_) {
      // Graceful fallback if device audio channel is muted or unavailable
    }
  }

  /// Pauses or stops the currently playing melody.
  Future<void> stopMusic() async {
    try {
      await _player?.stop();
      isPlayingNotifier.value = false;
    } catch (_) {}
  }

  /// Toggles playback state.
  Future<void> togglePlayback() async {
    if (isPlaying) {
      await stopMusic();
    } else {
      await playRomanticMelody();
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
    isPlayingNotifier.dispose();
  }
}
