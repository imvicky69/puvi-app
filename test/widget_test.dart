import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/theme/app_colors.dart';
import 'package:puvi/main.dart';

void main() {
  testWidgets('PuviApp launches with Love Letters placeholder screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PuviApp());
    await tester.pumpAndSettle();

    // Verify application title and subtitle are present
    expect(find.text('Puvi'), findsOneWidget);
    expect(find.text('Our little world.'), findsOneWidget);
    expect(find.text('a private place for two'), findsOneWidget);

    // Verify scaffold uses the ivory background
    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.backgroundColor, equals(AppColors.ivory));

    // Verify card is rendered
    expect(find.byType(Card), findsOneWidget);
  });
}
