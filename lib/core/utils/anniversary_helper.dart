import 'package:flutter/foundation.dart';

enum MilestoneType { monthly, halfYearly, yearly }

/// Represents an upcoming anniversary milestone for Puja & Vicky.
@immutable
class AnniversaryMilestone {
  final MilestoneType type;
  final String title;
  final String badge;
  final DateTime targetDate;
  final int count;

  const AnniversaryMilestone({
    required this.type,
    required this.title,
    required this.badge,
    required this.targetDate,
    required this.count,
  });

  /// Computes remaining time until milestone.
  Duration timeUntil([DateTime? now]) {
    final current = now ?? DateTime.now();
    final diff = targetDate.difference(current);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Formatted minimal countdown clock string, e.g. "14d : 08h : 32m : 15s".
  String formattedCountdown([DateTime? now]) {
    final duration = timeUntil(now);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (days > 0) {
      return '${days}d : ${hStr}h : ${mStr}m : ${sStr}s';
    } else {
      return '${hStr}h : ${mStr}m : ${sStr}s';
    }
  }

  /// Compact formatted date e.g. "Nov 11, 2026".
  String formattedDate() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[targetDate.month - 1];
    return '$m ${targetDate.day}, ${targetDate.year}';
  }
}

/// Helper calculations for couple anniversary milestones and live relationship days.
abstract final class AnniversaryHelper {
  /// Default anniversary date for Puja & Vicky: April 11, 2026.
  static final DateTime defaultAnniversary = DateTime(2026, 4, 11);

  /// Calculates total live days together.
  static int calculateDaysTogether(DateTime startDate, [DateTime? now]) {
    final current = now ?? DateTime.now();
    if (current.isBefore(startDate)) {
      return (startDate.difference(current).inDays).abs();
    }
    return (current.difference(startDate).inDays).abs() + 1;
  }

  /// Calculates Next Monthly, Half-Yearly, and Yearly milestones.
  static List<AnniversaryMilestone> getUpcomingMilestones(
    DateTime startDate, [
    DateTime? now,
  ]) {
    final current = now ?? DateTime.now();
    final day = startDate.day;

    // 1. Next Monthly Anniversary
    var mYear = current.year;
    var mMonth = current.month;
    var mDate = DateTime(mYear, mMonth, day);
    if (!mDate.isAfter(current)) {
      mMonth += 1;
      if (mMonth > 12) {
        mMonth = 1;
        mYear += 1;
      }
      mDate = DateTime(mYear, mMonth, day);
    }
    final monthsTogether =
        (mDate.year - startDate.year) * 12 + (mDate.month - startDate.month);
    final nextMonthly = AnniversaryMilestone(
      type: MilestoneType.monthly,
      title: 'Month $monthsTogether Celebration',
      badge: 'Monthly Anniv',
      targetDate: mDate,
      count: monthsTogether,
    );

    // 2. Next Half-Yearly Anniversary (every 6 months: 6, 12, 18, 24...)
    var hMonths = 6;
    DateTime hDate;
    while (true) {
      final y = startDate.year + (startDate.month - 1 + hMonths) ~/ 12;
      final m = (startDate.month - 1 + hMonths) % 12 + 1;
      hDate = DateTime(y, m, day);
      if (hDate.isAfter(current)) break;
      hMonths += 6;
    }
    final halfYearTitle = (hMonths % 12 == 0)
        ? '${hMonths ~/ 12} Year Anniversary'
        : '${(hMonths / 12).toStringAsFixed(1)} Years Milestone';
    final nextHalfYearly = AnniversaryMilestone(
      type: MilestoneType.halfYearly,
      title: halfYearTitle,
      badge: 'Half-Yearly',
      targetDate: hDate,
      count: hMonths,
    );

    // 3. Next Yearly Anniversary (April 11 each year)
    var yDate = DateTime(current.year, startDate.month, day);
    if (!yDate.isAfter(current)) {
      yDate = DateTime(current.year + 1, startDate.month, day);
    }
    final yearsCount = yDate.year - startDate.year;
    final nextYearly = AnniversaryMilestone(
      type: MilestoneType.yearly,
      title: '$yearsCount${_ordinal(yearsCount)} Year Anniversary',
      badge: 'Yearly Milestone',
      targetDate: yDate,
      count: yearsCount,
    );

    return [nextMonthly, nextHalfYearly, nextYearly];
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
