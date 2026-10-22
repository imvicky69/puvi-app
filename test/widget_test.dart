import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/theme/app_colors.dart';
import 'package:puvi/main.dart';

void main() {
  testWidgets('PuviApp launches with Love Letters LoginScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PuviApp());
    await tester.pumpAndSettle();

    // Verify application title and cute greeting
    expect(find.text('Puvi'), findsOneWidget);
    expect(find.text('our private corner'), findsOneWidget);
    expect(find.text('Step in to cherish our memories.'), findsOneWidget);

    // Verify input fields are present
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Secret Passcode'), findsOneWidget);

    // Verify Sign In and Google Sign In buttons are present
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);

    // Verify scaffold uses the ivory background
    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.backgroundColor, equals(AppColors.ivory));
  });
}
