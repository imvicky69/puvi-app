import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/theme/app_colors.dart';
import 'package:puvi/features/auth/login_screen.dart';
import 'package:puvi/features/home/presentation/main_nav_screen.dart';
import 'package:puvi/main.dart';

void main() {
  testWidgets(
    'PuviApp complete flow: Login, Main Navigation, Account Screen and Sign Out',
    (WidgetTester tester) async {
      await tester.pumpWidget(const PuviApp());
      await tester.pumpAndSettle();

      // 1. Verify LoginScreen elements
      expect(find.text('Puvi'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Passcode'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      // Verify background color
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.backgroundColor, equals(AppColors.ivory));

      // 2. Tap Google Sign In button to navigate to MainNavScreen
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // 3. Verify MainNavScreen is rendered
      expect(find.byType(MainNavScreen), findsOneWidget);

      // 4. Verify HomeHeader is present with user name and chat icon
      expect(find.text('Vicky'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);

      // Verify Dynamic Hero Card and Romantic Actions
      expect(find.text('LOVE BIRDS'), findsOneWidget);
      expect(find.text('Send Love'), findsOneWidget);
      expect(find.text('Love Whisper'), findsOneWidget);

      // Test Love Whisper modal
      await tester.ensureVisible(find.text('Love Whisper'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Love Whisper'));
      await tester.pumpAndSettle();
      expect(find.text('Today\'s Love Note'), findsOneWidget);
      await tester.tap(find.text('Close Whisper'));
      await tester.pumpAndSettle();

      // 5. Verify the 4 bottom navigation items exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // 6. Test Gallery tab with postcard layout and filters
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      expect(find.text('Cherished Postcards • Vicky & Puja'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Photos ('), findsOneWidget);

      // 7. Test Account tab with user & partner data
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      // Verify Account Screen elements
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('April 11, 2026'), findsOneWidget);
      expect(find.text('Connected & In Sync'), findsOneWidget);
      expect(find.text('App Lock'), findsOneWidget);
      expect(find.text('Love Notifications'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // 7. Test Logout confirmation dialog
      await tester.ensureVisible(find.text('Sign Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out of Puvi?'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);

      // Confirm sign out in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Out'));
      await tester.pumpAndSettle();

      // Verify we returned to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
