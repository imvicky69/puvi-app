import 'package:flutter/material.dart';
import '../services/couple_encryption_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Centralized, high-fidelity avatar component for Puja & Vicky.
///
/// Features:
/// - Maps user names, emails, and verified Firebase UIDs to the custom mascot portraits:
///   - Vicky: `assets/vicky-pfp.png`
///   - Puja: `assets/puja-pfp.png`
/// - Warm stationery backing circle so transparent cutout portraits blend smoothly.
/// - Graceful initial-monogram fallback during image loading or tests.
/// - Configurable sizing, borders, shadows, and interactive tap-to-view preview.
class PuviAvatar extends StatelessWidget {
  final String? nameOrUid;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final bool showShadow;
  final VoidCallback? onTap;

  const PuviAvatar({
    super.key,
    required this.nameOrUid,
    this.size = 40.0,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.2,
    this.backgroundColor,
    this.showShadow = false,
    this.onTap,
  });

  /// Factory helper specifically for Vicky.
  const PuviAvatar.vicky({
    super.key,
    this.size = 40.0,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.2,
    this.backgroundColor,
    this.showShadow = false,
    this.onTap,
  }) : nameOrUid = 'Vicky';

  /// Factory helper specifically for Puja.
  const PuviAvatar.puja({
    super.key,
    this.size = 40.0,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 1.2,
    this.backgroundColor,
    this.showShadow = false,
    this.onTap,
  }) : nameOrUid = 'Puja';

  /// Determines whether the provided name, email, or UID belongs to Vicky.
  static bool isVicky(String? input) {
    if (input == null || input.isEmpty) return true;
    final lower = input.toLowerCase().trim();

    // Check for explicit Puja identifiers
    if (lower.contains('puja') ||
        lower == CoupleEncryptionService.pujaUid.toLowerCase() ||
        lower == 'puja@puvi.com') {
      return false;
    }

    // Default to Vicky
    return true;
  }

  /// Returns the asset path corresponding to the given user.
  static String assetFor(String? input) {
    return isVicky(input) ? 'assets/vicky-pfp.png' : 'assets/puja-pfp.png';
  }

  /// Returns the normalized display name.
  static String displayNameFor(String? input) {
    return isVicky(input) ? 'Vicky' : 'Puja';
  }

  @override
  Widget build(BuildContext context) {
    final vicky = isVicky(nameOrUid);
    final assetPath = vicky ? 'assets/vicky-pfp.png' : 'assets/puja-pfp.png';
    final initial = vicky ? 'V' : 'P';
    final effectiveBorderColor = borderColor ?? AppColors.border;
    final effectiveBg =
        backgroundColor ?? AppColors.blushSand.withValues(alpha: 0.5);

    Widget avatarContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: effectiveBorderColor, width: borderWidth)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.espresso.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) {
            // Elegant monogram fallback for test environments or asset missing
            return Container(
              color: AppColors.blushSand,
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTypography.h3.copyWith(
                  fontSize: size * 0.44,
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarContent);
    }

    return avatarContent;
  }
}
