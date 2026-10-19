import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/domain/calendar/calendar_date.dart';
import 'package:money_path/domain/goals/contribution_frequency.dart';
import 'package:money_path/domain/goals/emergency_fund.dart';
import 'package:money_path/domain/goals/savings_schedule.dart';
import 'package:money_path/domain/money/money.dart';
import 'package:money_path/domain/reports/month_comparison.dart';
import 'package:money_path/domain/reports/savings_history.dart';

void main() {
  group('SpendingChange', () {
    test('15% more on groceries than last month', () {
      final change = SpendingChange.between(previous: Money.dollars(20000), current: Money.dollars(23000));
      expect((change as PercentChange).percent, 15);
    });

    test('less spending is a negative change', () {
      final change = SpendingChange.between(previous: Money.dollars(200), current: Money.dollars(150));
      expect((change as PercentChange).percent, -25);
    });

    test('rounds to the nearest whole percent', () {
      final change = SpendingChange.between(previous: Money.dollars(300), current: Money.dollars(301));
      expect((change as PercentChange).percent, 0);
    });

    test('spending where there was none is new, not infinite', () {
      expect(SpendingChange.between(previous: Money.zero, current: Money.dollars(5)), isA<NewThisMonth>());
    });
  });

  group('SavingsHistory', () {
    final schedule = SavingsSchedule(
      target: Money.dollars(1200),
      start: CalendarDate(2026, 1, 1),
      end: CalendarDate(2026, 12, 31),
      frequency: ContributionFrequency.monthly,
    );
    final movements = [
      DatedAmount(CalendarDate(2026, 1, 10), Money.dollars(100)),
      DatedAmount(CalendarDate(2026, 2, 10), Money.dollars(150)),
      DatedAmount(CalendarDate(2026, 3, 2), Money.dollars(-50)),
    ];

    test('has a point at the start and at each period end up to today', () {
      final points = SavingsHistory(schedule).pointsUpTo(CalendarDate(2026, 3, 15), movements);
      expect(points.map((p) => p.date.toIso()), ['2026-01-01', '2026-01-31', '2026-02-28', '2026-03-15']);
    });

    test('actual counts withdrawals against deposits', () {
      final points = SavingsHistory(schedule).pointsUpTo(CalendarDate(2026, 3, 15), movements);
      expect(points.last.actual, Money.dollars(200));
    });

    test('expected on a partial period is that period\'s full amount', () {
      final points = SavingsHistory(schedule).pointsUpTo(CalendarDate(2026, 3, 15), movements);
      expect(points.last.expected, Money.dollars(300));
    });
  });

  group('EmergencyFundTemplate', () {
    test('three months of average spending', () {
      final suggestion = const EmergencyFundTemplate()
          .suggest([Money.dollars(90000), Money.dollars(110000), Money.dollars(100000)]) as SuggestedTarget;
      expect(suggestion.target, Money.dollars(300000));
    });

    test('averages only months that had spending', () {
      final suggestion = const EmergencyFundTemplate()
          .suggest([Money.dollars(80000), Money.zero]) as SuggestedTarget;
      expect(suggestion.monthsAveraged, 1);
    });

    test('with no spending yet there is nothing to suggest', () {
      expect(const EmergencyFundTemplate().suggest([]), isA<NoSpendingHistory>());
    });
  });
}
