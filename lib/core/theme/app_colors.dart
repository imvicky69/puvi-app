import 'package:flutter/material.dart';

/// Centralized, strongly typed color tokens for the Puvi application.
///
/// Aesthetic: Love Letters — warm paper-like surfaces, romantic editorial
/// typography, deep burgundy accents, and serene muted tones.
abstract final class AppColors {
  // --- Raw Palette Tokens ---

  /// Warm parchment background tone (#F7F1E8).
  static const Color ivory = Color(0xFFF7F1E8);

  /// Crisp, clean card & modal surface (#FFFCF8).
  static const Color paper = Color(0xFFFFFCF8);

  /// Deep romantic primary action & hero accent (#702D40).
  static const Color burgundy = Color(0xFF702D40);

  /// Deep rich primary reading text (#302522).
  static const Color espresso = Color(0xFF302522);

  /// Soft warm accent & secondary highlight (#D9A6A1).
  static const Color dustyRose = Color(0xFFD9A6A1);

  /// Delicate warm neutral container & chip background (#EDE1D5).
  static const Color blushSand = Color(0xFFEDE1D5);

  /// Balanced secondary text & muted icon tone (#6F625C).
  static const Color taupe = Color(0xFF6F625C);

  /// Subtle hair-line border for structural containment (#E8DDD2).
  static const Color border = Color(0xFFE8DDD2);

  /// Reserved semantic error state tone (#B3261E).
  static const Color error = Color(0xFFB3261E);

  /// Reserved semantic success state tone (#476B51).
  static const Color success = Color(0xFF476B51);

  // --- Semantic Role Mappings ---

  /// App scaffold background surface.
  static const Color background = ivory;

  /// Card, sheet, and floating surface.
  static const Color cardSurface = paper;

  /// Primary interactive CTA & active indicator.
  static const Color primaryAction = burgundy;

  /// Contrast foreground on primary actions.
  static const Color onPrimary = paper;

  /// Primary editorial & body text.
  static const Color textPrimary = espresso;

  /// Secondary metadata, subheadings & captions.
  static const Color textSecondary = taupe;

  /// Inverse contrast text (e.g., on dark banner).
  static const Color textInverse = paper;

  /// Structural card and input divider border.
  static const Color borderPrimary = border;

  /// Softer border / divider separator.
  static const Color borderSubtle = blushSand;

  /// Container fill for chips, pills, and subtle panels.
  static const Color container = blushSand;

  /// Secondary container / soft romantic accent surface.
  static const Color containerAccent = dustyRose;

  /// Semantic error feedback.
  static const Color stateError = error;

  /// Semantic success confirmation.
  static const Color stateSuccess = success;
}
