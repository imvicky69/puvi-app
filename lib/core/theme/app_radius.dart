import 'package:flutter/widgets.dart';

/// Centralized border radius tokens for the Puvi application.
///
/// Embodies playful, soft rounded surfaces characteristic of the Love Letters aesthetic.
abstract final class AppRadius {
  // --- Raw Radius Values ---

  /// Small accent radius (4px).
  static const double xsValue = 4.0;

  /// Subtle chip radius (8px).
  static const double smValue = 8.0;

  /// Medium component radius (12px).
  static const double mdValue = 12.0;

  /// Standard interactive button & input radius (16px).
  static const double buttonValue = 16.0;

  /// Standard card surface radius (20px).
  static const double cardValue = 20.0;

  /// Large hero / feature card radius (28px).
  static const double largeCardValue = 28.0;

  /// Fully rounded pill / stadium curve (999px).
  static const double pillValue = 999.0;

  // --- Radius Tokens ---
  static const Radius xs = Radius.circular(xsValue);
  static const Radius sm = Radius.circular(smValue);
  static const Radius md = Radius.circular(mdValue);
  static const Radius button = Radius.circular(buttonValue);
  static const Radius card = Radius.circular(cardValue);
  static const Radius largeCard = Radius.circular(largeCardValue);
  static const Radius pill = Radius.circular(pillValue);

  // --- BorderRadius Tokens ---
  static const BorderRadius borderXs = BorderRadius.all(xs);
  static const BorderRadius borderSm = BorderRadius.all(sm);
  static const BorderRadius borderMd = BorderRadius.all(md);
  static const BorderRadius borderButton = BorderRadius.all(button);
  static const BorderRadius borderCard = BorderRadius.all(card);
  static const BorderRadius borderLargeCard = BorderRadius.all(largeCard);
  static const BorderRadius borderPill = BorderRadius.all(pill);
}
