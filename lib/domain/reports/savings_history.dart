import '../calendar/calendar_date.dart';
import '../goals/savings_schedule.dart';
import '../money/money.dart';

/// A deposit (positive) or withdrawal (negative) on a day.
class DatedAmount {
  const DatedAmount(this.date, this.amount);

  final CalendarDate date;
  final Money amount;
}

class SavingsPoint {
  const SavingsPoint({required this.date, required this.expected, required this.actual});

  final CalendarDate date;
  final Money expected;
  final Money actual;
}

/// Actual against expected savings at the end of every period so far,
/// for the "savings over time" line chart.
class SavingsHistory {
  const SavingsHistory(this.schedule);

  final SavingsSchedule schedule;

  List<SavingsPoint> pointsUpTo(CalendarDate today, List<DatedAmount> movements) {
    final points = [SavingsPoint(date: schedule.start, expected: Money.zero, actual: Money.zero)];
    for (var index = 0; index < schedule.totalPeriods; index++) {
      final periodEnd = schedule.periodEnd(index);
      final pointDate = periodEnd.isAfter(today) ? today : periodEnd;
      points.add(_pointAt(pointDate, index + 1, movements));
      if (periodEnd.isOnOrAfter(today)) break;
    }
    return points;
  }

  SavingsPoint _pointAt(CalendarDate date, int periodsPaid, List<DatedAmount> movements) {
    final actual = Money.sum(movements.where((m) => m.date.isOnOrBefore(date)).map((m) => m.amount));
    return SavingsPoint(date: date, expected: schedule.expectedAfter(periodsPaid), actual: actual);
  }
}
