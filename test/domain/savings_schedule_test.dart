import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/domain/calendar/calendar_date.dart';
import 'package:money_path/domain/goals/contribution_frequency.dart';
import 'package:money_path/domain/goals/savings_schedule.dart';
import 'package:money_path/domain/money/money.dart';

SavingsSchedule oneYear(ContributionFrequency frequency) => SavingsSchedule(
      target: Money.dollars(1200),
      start: CalendarDate(2026, 1, 1),
      end: CalendarDate(2026, 12, 31),
      frequency: frequency,
    );

void main() {
  test('a year paid monthly is twelve periods of \$100', () {
    final schedule = oneYear(ContributionFrequency.monthly);
    expect(schedule.totalPeriods, 12);
    expect(schedule.requiredPerPeriod, Money.dollars(100));
  });

  test('a year paid weekly is 52 periods', () {
    expect(oneYear(ContributionFrequency.weekly).totalPeriods, 52);
  });

  test('a year paid fortnightly is 26 periods', () {
    expect(oneYear(ContributionFrequency.fortnightly).totalPeriods, 26);
  });

  test('per-week and per-month figures do not depend on the chosen frequency', () {
    final schedule = oneYear(ContributionFrequency.fortnightly);
    expect(schedule.requiredPerWeek, const Money.cents(2308));
    expect(schedule.requiredPerMonth, Money.dollars(100));
  });

  test('the last period ends on the end date', () {
    final schedule = oneYear(ContributionFrequency.weekly);
    expect(schedule.periodEnd(51), CalendarDate(2026, 12, 31));
  });

  test('a period ends the day before the next one starts', () {
    final schedule = oneYear(ContributionFrequency.monthly);
    expect(schedule.periodEnd(0), CalendarDate(2026, 1, 31));
  });

  test('monthly periods from the 31st land on each month\'s last day', () {
    final schedule = SavingsSchedule(
      target: Money.dollars(300),
      start: CalendarDate(2026, 1, 31),
      end: CalendarDate(2026, 4, 29),
      frequency: ContributionFrequency.monthly,
    );
    expect(schedule.periodStart(1), CalendarDate(2026, 2, 28));
    expect(schedule.periodStart(2), CalendarDate(2026, 3, 31));
  });

  test('no period is complete during the first one', () {
    final schedule = oneYear(ContributionFrequency.monthly);
    expect(schedule.completedPeriodsOn(CalendarDate(2026, 1, 31)), 0);
  });

  test('a period counts as complete the day after it ends', () {
    final schedule = oneYear(ContributionFrequency.monthly);
    expect(schedule.completedPeriodsOn(CalendarDate(2026, 2, 1)), 1);
  });

  test('expected never exceeds the target', () {
    final schedule = oneYear(ContributionFrequency.weekly);
    expect(schedule.expectedAfter(52), Money.dollars(1200));
  });

  test('an end date before the start is refused', () {
    expect(
      () => SavingsSchedule(
        target: Money.dollars(1),
        start: CalendarDate(2026, 5, 1),
        end: CalendarDate(2026, 4, 1),
        frequency: ContributionFrequency.monthly,
      ),
      throwsArgumentError,
    );
  });
}
