import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/services/app_lock_service.dart';
import 'package:puvi/features/account/presentation/widgets/couple_stats_card.dart';
import 'package:puvi/features/account/presentation/widgets/set_backup_pin_dialog.dart';

void main() {
  group('AppLockService Logic Tests', () {
    test('Default state is disabled and unlocked in test runner', () async {
      await AppLockService.initialize();
      expect(AppLockService.isEnabled, isFalse);
      expect(AppLockService.isLocked, isFalse);
      expect(AppLockService.isEnabledNotifier.value, isFalse);
    });

    test('enableLock sets PIN and enables lock', () async {
      await AppLockService.enableLock(pin: '1234', useBiometrics: true);
      expect(AppLockService.isEnabled, isTrue);
      expect(AppLockService.isEnabledNotifier.value, isTrue);
      expect(AppLockService.hasPin, isTrue);

      // Verify PIN
      expect(AppLockService.verifyPin('1234'), isTrue);
      expect(AppLockService.verifyPin('9999'), isFalse);

      // Disable lock
      await AppLockService.disableLock();
      expect(AppLockService.isEnabled, isFalse);
      expect(AppLockService.isEnabledNotifier.value, isFalse);
    });
  });

  group('CoupleStatsCard & Anniversary Ticker Tests', () {
    testWidgets('Renders unified 205 days together and upcoming milestone', (
      tester,
    ) async {
      final anniversary = DateTime(2026, 4, 11);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CoupleStatsCard(anniversaryDate: anniversary)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Together Since'), findsOneWidget);
      expect(find.text('April 11, 2026'), findsOneWidget);
      expect(find.text('Days of Love'), findsOneWidget);
      expect(find.text('Our Forever Journey'), findsOneWidget);

      // Tapping card opens AnniversaryMilestoneSheet
      await tester.tap(find.byType(CoupleStatsCard));
      await tester.pumpAndSettle();

      expect(find.text('Our Milestones'), findsOneWidget);
      expect(
        find.textContaining('days of our beautiful story'),
        findsOneWidget,
      );
    });
  });

  group('PIN Dialogs Tests', () {
    testWidgets('SetBackupPinDialog inputs and confirms 4 digits', (
      tester,
    ) async {
      String? returnedPin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  returnedPin = await SetBackupPinDialog.show(ctx);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Set 4-Digit Backup PIN'), findsOneWidget);

      // Type 1, 2, 3, 4
      await tester.tap(find.widgetWithText(OutlinedButton, '1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '2'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '3'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '4'));
      await tester.pumpAndSettle();

      // Dialog transitions to Confirm Backup PIN
      expect(find.text('Confirm Backup PIN'), findsOneWidget);

      // Re-enter 1, 2, 3, 4 to confirm
      await tester.tap(find.widgetWithText(OutlinedButton, '1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '2'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '3'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '4'));
      await tester.pumpAndSettle();

      // Dialog closes and returns '1234'
      expect(returnedPin, equals('1234'));
    });
  });
}
