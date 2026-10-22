import 'package:flutter/animation.dart';

/// Centralized animation durations and curves for the Puvi application.
///
/// Embodies restrained, calm motion that feels gentle, natural, and intimate.
abstract final class AppMotion {
  // --- Durations ---

  /// Quick feedback for buttons, touch ripples, and icon state changes (150ms).
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard duration for card expansions, fade transitions, and toggles (250ms).
  static const Duration medium = Duration(milliseconds: 250);

  /// Expressive duration for page transitions, bottom sheets, and hero reveals (350ms).
  static const Duration slow = Duration(milliseconds: 350);

  // --- Curves ---

  /// Gentle, natural decelerating curve for entrances and expands.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Smooth symmetrical curve for continuous or bidirectional state shifts.
  static const Curve easeInOut = Curves.easeInOut;

  /// Expressive cubic curve for full page journeys.
  static const Curve standard = Curves.easeInOutCubic;

  /// Restrained playful accent curve for subtle badge pops.
  static const Curve gentlePop = Curves.easeOutBack;
}
