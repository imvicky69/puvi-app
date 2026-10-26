import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_motion.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Central Material 3 light theme configuration for the Puvi application.
///
/// Implements the "Love Letters" aesthetic:
/// - Warm paper-like surfaces and ivory backdrop.
/// - Romantic editorial serif headings (Cormorant Garamond).
/// - Modern readable sans body & labels (DM Sans).
/// - Deep burgundy primary action accents.
/// - Transparent surface tints to prevent Material 3 purple tint overlay.
abstract final class AppTheme {
  /// The single, canonical light theme for Puvi.
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.burgundy,
      onPrimary: AppColors.paper,
      primaryContainer: AppColors.blushSand,
      onPrimaryContainer: AppColors.burgundy,
      secondary: AppColors.dustyRose,
      onSecondary: AppColors.espresso,
      secondaryContainer: AppColors.blushSand,
      onSecondaryContainer: AppColors.espresso,
      tertiary: AppColors.taupe,
      onTertiary: AppColors.paper,
      error: AppColors.error,
      onError: AppColors.paper,
      surface: AppColors.paper,
      onSurface: AppColors.espresso,
      surfaceContainerLowest: AppColors.paper,
      surfaceContainerLow: AppColors.paper,
      surfaceContainer: AppColors.blushSand,
      surfaceContainerHigh: AppColors.blushSand,
      surfaceContainerHighest: AppColors.dustyRose,
      outline: AppColors.border,
      outlineVariant: AppColors.blushSand,
      shadow: Colors.black26,
    );

    final textTheme = AppTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ivory,
      canvasColor: AppColors.paper,
      textTheme: textTheme,

      // --- AppBar Theme ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.espresso,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: AppTypography.h3,
        iconTheme: const IconThemeData(color: AppColors.espresso, size: 24),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // --- Card Theme ---
      cardTheme: const CardThemeData(
        color: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderCard,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // --- ElevatedButton Theme ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.burgundy,
          foregroundColor: AppColors.paper,
          disabledBackgroundColor: AppColors.blushSand,
          disabledForegroundColor: AppColors.taupe,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size(
            AppSpacing.minTouchTargetSize,
            AppSpacing.minTouchTargetSize,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderButton,
          ),
          textStyle: AppTypography.label.copyWith(
            color: AppColors.paper,
            fontWeight: FontWeight.w600,
          ),
          animationDuration: AppMotion.fast,
        ),
      ),

      // --- OutlinedButton Theme ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.burgundy,
          disabledForegroundColor: AppColors.taupe,
          minimumSize: const Size(
            AppSpacing.minTouchTargetSize,
            AppSpacing.minTouchTargetSize,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderButton,
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          animationDuration: AppMotion.fast,
        ),
      ),

      // --- TextButton Theme ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.burgundy,
          disabledForegroundColor: AppColors.taupe,
          minimumSize: const Size(
            AppSpacing.minTouchTargetSize,
            AppSpacing.minTouchTargetSize,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderButton,
          ),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          animationDuration: AppMotion.fast,
        ),
      ),

      // --- Input Decoration Theme ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.taupe),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.espresso,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderButton,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderButton,
          borderSide: BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderButton,
          borderSide: BorderSide(color: AppColors.burgundy, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderButton,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderButton,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // --- NavigationBar Theme ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.blushSand,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              color: AppColors.burgundy,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.caption.copyWith(color: AppColors.taupe);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.burgundy, size: 24);
          }
          return const IconThemeData(color: AppColors.taupe, size: 24);
        }),
      ),

      // --- Divider Theme ---
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // --- SnackBar Theme ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.espresso,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.paper,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // --- Dialog Theme ---
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderLargeCard,
          side: BorderSide.none,
        ),
        titleTextStyle: AppTypography.h2,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // --- BottomSheet Theme ---
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.largeCard),
        ),
      ),

      // --- FloatingActionButton Theme ---
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.burgundy,
        foregroundColor: AppColors.paper,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderButton),
      ),
    );
  }
}
