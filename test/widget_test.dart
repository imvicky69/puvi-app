import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/theme/app_colors.dart';
import 'package:puvi/features/home/presentation/main_nav_screen.dart';
import 'package:puvi/main.dart';

void main() {
  testWidgets(
    'PuviApp launches with compact LoginScreen and navigates to MainNavScreen',
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

      // 5. Verify the 4 bottom navigation items exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // 6. Test tab switching
      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();
      expect(find.text('Milestones & Chapters'), findsOneWidget);

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();
      expect(find.text('Our Shared Frames'), findsOneWidget);

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Couple Profile'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Our sanctuary is ready'), findsOneWidget);
    },
  );
}
