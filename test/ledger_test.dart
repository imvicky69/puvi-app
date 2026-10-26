import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/features/ledger/data/ledger_entry.dart';
import 'package:puvi/features/ledger/data/ledger_repository.dart';

void main() {
  group('LedgerEntry & LedgerRepository Math Tests', () {
    test('Calculates equal 50/50 split balance correctly', () {
      final entries = [
        LedgerEntry(
          id: '1',
          title: 'Zomato Dinner',
          totalBill: 2400.0,
          owedAmount: 1200.0,
          paidBy: 'Vicky',
          owedBy: 'Puja',
          date: DateTime.now(),
          type: LedgerType.split,
          splitMode: SplitMode.equal,
        ),
      ];

      // For Vicky: Partner (Puja) owes ₹1200 (+1200)
      final vickyBalance = LedgerRepository.calculateNetBalance(
        entries,
        'Vicky',
      );
      expect(vickyBalance, 1200.0);

      // For Puja: Puja owes Vicky ₹1200 (-1200)
      final pujaBalance = LedgerRepository.calculateNetBalance(entries, 'Puja');
      expect(pujaBalance, -1200.0);
    });

    test('Calculates net balance across multiple mutual expenses', () {
      final entries = [
        // Vicky paid 2400 (50/50 split -> Puja owes 1200)
        LedgerEntry(
          id: '1',
          title: 'Dinner',
          totalBill: 2400.0,
          owedAmount: 1200.0,
          paidBy: 'Vicky',
          owedBy: 'Puja',
          date: DateTime.now(),
          type: LedgerType.split,
        ),
        // Puja paid 850 (50/50 split -> Vicky owes 425)
        LedgerEntry(
          id: '2',
          title: 'Groceries',
          totalBill: 850.0,
          owedAmount: 425.0,
          paidBy: 'Puja',
          owedBy: 'Vicky',
          date: DateTime.now(),
          type: LedgerType.split,
        ),
        // Vicky paid 100% coffee for Puja (400 -> Puja owes 400)
        LedgerEntry(
          id: '3',
          title: 'Coffee',
          totalBill: 400.0,
          owedAmount: 400.0,
          paidBy: 'Vicky',
          owedBy: 'Puja',
          date: DateTime.now(),
          type: LedgerType.lent,
          splitMode: SplitMode.none,
        ),
      ];

      // Vicky: +1200 - 425 + 400 = +1175 (Puja owes Vicky ₹1175)
      final vickyBalance = LedgerRepository.calculateNetBalance(
        entries,
        'Vicky',
      );
      expect(vickyBalance, 1175.0);

      // Puja: -1200 + 425 - 400 = -1175 (Puja owes Vicky ₹1175)
      final pujaBalance = LedgerRepository.calculateNetBalance(entries, 'Puja');
      expect(pujaBalance, -1175.0);
    });

    test('Settled items are excluded from net balance calculation', () {
      final entries = [
        LedgerEntry(
          id: '1',
          title: 'Old Dinner',
          totalBill: 2000.0,
          owedAmount: 1000.0,
          paidBy: 'Vicky',
          owedBy: 'Puja',
          date: DateTime.now(),
          isSettled: true,
        ),
        LedgerEntry(
          id: '2',
          title: 'New Movie',
          totalBill: 600.0,
          owedAmount: 300.0,
          paidBy: 'Puja',
          owedBy: 'Vicky',
          date: DateTime.now(),
          isSettled: false,
        ),
      ];

      // Vicky owes Puja 300 -> balance is -300 for Vicky
      expect(LedgerRepository.calculateNetBalance(entries, 'Vicky'), -300.0);
      expect(LedgerRepository.calculateNetBalance(entries, 'Puja'), 300.0);
    });

    test('JSON serialization round-trip retains all split data', () {
      final now = DateTime.now();
      final entry = LedgerEntry(
        id: 'test_1',
        title: 'Cab ride to airport',
        totalBill: 1500.0,
        owedAmount: 750.0,
        paidBy: 'Vicky',
        owedBy: 'Puja',
        date: now,
        category: LedgerCategory.travel,
        note: 'Terminal 2 Uber',
        type: LedgerType.split,
        splitMode: SplitMode.equal,
        isSettled: false,
      );

      final json = entry.toJson();
      final revived = LedgerEntry.fromJson(json);

      expect(revived.id, 'test_1');
      expect(revived.title, 'Cab ride to airport');
      expect(revived.totalBill, 1500.0);
      expect(revived.owedAmount, 750.0);
      expect(revived.paidBy, 'Vicky');
      expect(revived.owedBy, 'Puja');
      expect(revived.category, LedgerCategory.travel);
      expect(revived.type, LedgerType.split);
      expect(revived.splitMode, SplitMode.equal);
      expect(revived.isSettled, false);
    });
  });
}
