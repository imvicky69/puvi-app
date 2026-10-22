import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Item data model for PuviBottomNavBar.
class PuviNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const PuviNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

/// Aesthetic, romantic bottom navigation bar for Puvi.
///
/// Features:
/// - Tactile paper container with soft border.
/// - Blush sand pill highlight for active tab.
/// - Burgundy active tint and taupe inactive tint.
/// - Smooth micro-transitions between destinations.
class PuviBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  static const List<PuviNavItem> items = [
    PuviNavItem(
      label: 'Home',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    PuviNavItem(
      label: 'Timeline',
      activeIcon: Icons.auto_stories_rounded,
      inactiveIcon: Icons.auto_stories_outlined,
    ),
    PuviNavItem(
      label: 'Gallery',
      activeIcon: Icons.photo_library_rounded,
      inactiveIcon: Icons.photo_library_outlined,
    ),
    PuviNavItem(
      label: 'Account',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  const PuviBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.easeOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.blushSand.withValues(alpha: 0.6)
                          : Colors.transparent,
                      borderRadius: AppRadius.borderPill,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: Icon(
                            isSelected ? item.activeIcon : item.inactiveIcon,
                            key: ValueKey(
                              '${item.label}_${isSelected ? "active" : "inactive"}',
                            ),
                            size: 22,
                            color: isSelected
                                ? AppColors.burgundy
                                : AppColors.taupe,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.burgundy
                                : AppColors.taupe,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
