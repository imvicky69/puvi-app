import 'package:flutter_test/flutter_test.dart';
import 'package:puvi/core/utils/anniversary_helper.dart';

void main() {
  group('AnniversaryHelper Tests', () {
    final start = DateTime(2026, 4, 11);

    test('calculateDaysTogether computes correct count', () {
      final now = DateTime(2026, 10, 28);
      final days = AnniversaryHelper.calculateDaysTogether(start, now);
      // April 11 to October 28 in 2026 is 200 days difference + 1 = 201 days
      expect(days, 201);
    });

    test('getUpcomingMilestones returns monthly, half-yearly and yearly', () {
      final now = DateTime(2026, 10, 28);
      final milestones = AnniversaryHelper.getUpcomingMilestones(start, now);

      expect(milestones.length, 3);

      final monthly = milestones[0];
      expect(monthly.type, MilestoneType.monthly);
      expect(monthly.targetDate, DateTime(2026, 11, 11));
      expect(monthly.count, 7);
      expect(monthly.title, contains('Month 7'));

      final halfYearly = milestones[1];
      expect(halfYearly.type, MilestoneType.halfYearly);
      expect(halfYearly.count % 6, 0);

      final yearly = milestones[2];
      expect(yearly.type, MilestoneType.yearly);
      expect(yearly.targetDate, DateTime(2027, 4, 11));
      expect(yearly.count, 1);
    });

    test('formattedCountdown formats days, hours, mins, secs', () {
      final target = DateTime(2026, 10, 30, 10, 0, 0);
      final now = DateTime(2026, 10, 28, 8, 30, 0);
      final milestone = AnniversaryMilestone(
        type: MilestoneType.monthly,
        title: 'Month 7',
        badge: 'Monthly',
        targetDate: target,
        count: 7,
      );

      final clock = milestone.formattedCountdown(now);
      expect(clock, contains('d :'));
      expect(clock, contains('h :'));
      expect(clock, contains('m :'));
    });
  });
}
