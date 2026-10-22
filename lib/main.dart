import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_radius.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';

import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }
  runApp(const PuviApp());
}

/// Root application widget for Puvi.
class PuviApp extends StatelessWidget {
  const PuviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puvi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}

/// Minimal, responsive placeholder home screen for the Puvi foundation.
///
/// Embodies the "Love Letters" aesthetic with warm paper surfaces,
/// Cormorant Garamond editorial display typography, and DM Sans body text.
class PuviPlaceholderScreen extends StatelessWidget {
  const PuviPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppSpacing.verticalXl,

                  // Intimate handwritten accent
                  Text(
                    'a private place for two',
                    style: AppTypography.handwrittenNote,
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.verticalSm,

                  // Main editorial title in Cormorant Garamond
                  Text(
                    'Puvi',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: AppColors.espresso,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.verticalXs,

                  // Subtitle in DM Sans
                  Text(
                    'Our little world.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.taupe,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.verticalXxl,

                  // Editorial paper card showcasing design system harmony
                  Card(
                    child: Padding(
                      padding: AppSpacing.cardInsets,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.dustyRose,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              AppSpacing.horizontalSm,
                              Text(
                                'Love Letters Theme',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.taupe,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              AppSpacing.horizontalSm,
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.dustyRose,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.verticalMd,
                          const Divider(),
                          AppSpacing.verticalMd,
                          Text(
                            'Warm paper surfaces, deep burgundy accents, and gentle typography — ready for our memories.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.espresso,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.verticalLg,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.blushSand,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Text(
                              'Foundation Ready',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.burgundy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppSpacing.verticalXxl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
