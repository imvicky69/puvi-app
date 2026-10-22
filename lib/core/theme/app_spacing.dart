import 'package:flutter/widgets.dart';

/// Centralized spacing tokens based on a 4px grid system for the Puvi application.
abstract final class AppSpacing {
  // --- 4px Grid Base Scale ---

  /// 4px grid step (xxs).
  static const double xxs = 4.0;

  /// 8px grid step (xs).
  static const double xs = 8.0;

  /// 12px grid step (sm).
  static const double sm = 12.0;

  /// 16px grid step (md).
  static const double md = 16.0;

  /// 24px grid step (lg).
  static const double lg = 24.0;

  /// 32px grid step (xl).
  static const double xl = 32.0;

  /// 48px grid step (xxl).
  static const double xxl = 48.0;

  /// 64px grid step (xxxl).
  static const double xxxl = 64.0;

  // --- Semantic Measurements ---

  /// Standard screen horizontal margin (24px).
  static const double screenHorizontal = lg;

  /// Standard card internal padding (20px).
  static const double cardPadding = 20.0;

  /// Compact card internal padding (16px).
  static const double cardPaddingCompact = md;

  /// Minimum accessible touch target size (48px).
  static const double minTouchTargetSize = 48.0;

  // --- EdgeInsets Shortcuts ---

  /// Default screen horizontal padding: `EdgeInsets.symmetric(horizontal: 24)`.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  /// Default full screen padding with balanced vertical inset: `EdgeInsets.all(24)`.
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(screenHorizontal);

  /// Standard card padding: `EdgeInsets.all(20)`.
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);

  /// Compact card padding: `EdgeInsets.all(16)`.
  static const EdgeInsets cardInsetsCompact = EdgeInsets.all(
    cardPaddingCompact,
  );

  // --- BoxConstraints ---

  /// Minimum interactive touch target constraint (48x48 logical pixels).
  static const BoxConstraints minTouchTarget = BoxConstraints(
    minWidth: minTouchTargetSize,
    minHeight: minTouchTargetSize,
  );

  // --- Vertical Spacer Widgets ---
  static const SizedBox verticalXxs = SizedBox(height: xxs);
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox verticalXxl = SizedBox(height: xxl);
  static const SizedBox verticalXxxl = SizedBox(height: xxxl);

  // --- Horizontal Spacer Widgets ---
  static const SizedBox horizontalXxs = SizedBox(width: xxs);
  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);
  static const SizedBox horizontalXl = SizedBox(width: xl);
  static const SizedBox horizontalXxl = SizedBox(width: xxl);
  static const SizedBox horizontalXxxl = SizedBox(width: xxxl);
}
