import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography system for the Puvi application.
///
/// Aesthetic: Love Letters
/// - **Cormorant Garamond**: Expressive display and editorial headings.
/// - **DM Sans**: Functional body, buttons, navigation, and metadata.
/// - **Caveat**: Optional handwritten notes and decorative intimate accents.
abstract final class AppTypography {
  // --- Font Family Getters ---

  /// Display serif font family name.
  static String get displayFontFamily =>
      GoogleFonts.cormorantGaramond().fontFamily ?? 'Cormorant Garamond';

  /// Clean modern sans font family name for body and UI.
  static String get bodyFontFamily =>
      GoogleFonts.dmSans().fontFamily ?? 'DM Sans';

  /// Expressive handwritten script font family name.
  static String get handwrittenFontFamily =>
      GoogleFonts.caveat().fontFamily ?? 'Caveat';

  // --- Display & Headings (Cormorant Garamond) ---

  /// Hero display heading: 40px, w600, Cormorant Garamond.
  static final TextStyle display = GoogleFonts.cormorantGaramond(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.espresso,
  );

  /// Primary editorial title (H1): 32px, w600, Cormorant Garamond.
  static final TextStyle h1 = GoogleFonts.cormorantGaramond(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.3,
    color: AppColors.espresso,
  );

  /// Section heading (H2): 26px, w600, Cormorant Garamond.
  static final TextStyle h2 = GoogleFonts.cormorantGaramond(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.espresso,
  );

  /// Card & Subsection heading (H3): 20px, w600, Cormorant Garamond.
  static final TextStyle h3 = GoogleFonts.cormorantGaramond(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
    color: AppColors.espresso,
  );

  // --- Body & Functional Text (DM Sans) ---

  /// Primary body copy: 16px, w400, DM Sans.
  static final TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    color: AppColors.espresso,
  );

  /// Secondary body & list text: 14px, w400, DM Sans.
  static final TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.15,
    color: AppColors.taupe,
  );

  /// Interactive button & form labels: 14px, w600, DM Sans.
  static final TextStyle label = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.espresso,
  );

  /// Metadata, timestamps & captions: 12px, w500, DM Sans.
  static final TextStyle caption = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.2,
    color: AppColors.taupe,
  );

  /// Fine print / micro caption: 11px, w500, DM Sans.
  static final TextStyle captionSmall = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.taupe,
  );

  // --- Handwritten Romantic Accents (Caveat) ---

  /// Intimate handwritten memo / love note accent: 22px, w500, Caveat.
  static final TextStyle handwrittenNote = GoogleFonts.caveat(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: AppColors.burgundy,
  );

  /// Subtle handwritten decorative caption: 16px, w400, Caveat.
  static final TextStyle handwrittenCaption = GoogleFonts.caveat(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.taupe,
  );

  // --- Material 3 Reusable TextTheme ---

  /// Complete Material 3 [TextTheme] adhering to the Love Letters typography rules.
  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    displayMedium: display.copyWith(fontSize: 36),
    displaySmall: h1,
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    titleLarge: h3,
    titleMedium: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: AppColors.espresso,
    ),
    titleSmall: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: AppColors.espresso,
    ),
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: caption,
    labelLarge: label,
    labelMedium: label.copyWith(fontSize: 13),
    labelSmall: captionSmall,
  );
}
