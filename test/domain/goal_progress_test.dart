import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/domain/calendar/calendar_date.dart';
import 'package:money_path/domain/goals/contribution_frequency.dart';
import 'package:money_path/domain/goals/goal_progress.dart';
import 'package:money_path/domain/goals/goal_standing.dart';
import 'package:money_path/domain/goals/projection.dart';
import 'package:money_path/domain/goals/savings_schedule.dart';
import 'package:money_path/domain/money/money.dart';

final monthlyYear = SavingsSchedule(
  target: Money.dollars(1200),
  start: CalendarDate(2026, 1, 1),
  end: CalendarDate(2026, 12, 31),
  frequency: ContributionFrequency.monthly,
);

GoalProgress progressOn(CalendarDate today, int savedDollars, {int amber = 25}) =>
    GoalProgress(
      schedule: monthlyYear,
      saved: Money.dollars(savedDollars),
      today: today,
      amberThresholdPercent: amber,
    );

void main() {
  group('standing', () {
    test('\$120 against \$100 this month is on track, \$20 ahead', () {
      final standing = progressOn(CalendarDate(2026, 1, 20), 120).standing;
      expect(standing, isA<AheadOfPlan>());
      expect((standing as AheadOfPlan).ahead, Money.dollars(20));
    });

    test('\$80 mid-month is still on track with \$20 due by month end', () {
      final standing = progressOn(CalendarDate(2026, 1, 20), 80).standing as CurrentPeriodDue;
      expect(standing.due, Money.dollars(20));
      expect(standing.dueBy, CalendarDate(2026, 1, 31));
    });

    test('\$80 once the month is over is \$20 behind', () {
      final standing = progressOn(CalendarDate(2026, 2, 1), 80).standing as BehindPlan;
      expect(standing.behind, Money.dollars(20));
    });

    test('a shortfall inside the threshold is amber', () {
      final standing = progressOn(CalendarDate(2026, 2, 1), 80, amber: 25).standing;
      expect(standing.light, StatusLight.amber);
    });

    test('a shortfall beyond the threshold is red', () {
      final standing = progressOn(CalendarDate(2026, 2, 1), 80, amber: 10).standing;
      expect(standing.light, StatusLight.red);
    });

    test('before the start date the goal has not started', () {
      expect(progressOn(CalendarDate(2025, 12, 1), 0).standing, isA<NotStartedYet>());
    });

    test('after the end date an unmet goal is past its end date', () {
      final standing = progressOn(CalendarDate(2027, 1, 2), 900).standing as PastEndDate;
      expect(standing.stillNeeded, Money.dollars(300));
    });

    test('reaching the target wins over everything else', () {
      expect(progressOn(CalendarDate(2026, 3, 1), 1200).standing, isA<TargetReached>());
    });
  });

  group('amounts', () {
    test('remaining never goes below zero', () {
      expect(progressOn(CalendarDate(2026, 3, 1), 1500).remaining, Money.zero);
    });

    test('percent complete is capped at 100', () {
      expect(progressOn(CalendarDate(2026, 3, 1), 1500).percentComplete, 100);
    });

    test('catch-up spreads what is left over the periods still open', () {
      final progress = progressOn(CalendarDate(2026, 2, 5), 80);
      expect(progress.periodsLeft, 11);
      expect(progress.catchUpPerPeriod, const Money.cents(10182));
    });

    test('after the end date catch-up is everything still needed', () {
      expect(progressOn(CalendarDate(2027, 1, 5), 900).catchUpPerPeriod, Money.dollars(300));
    });
  });

  group('projection', () {
    test('projects the finish from the average daily rate', () {
      final projection = progressOn(CalendarDate(2026, 2, 5), 80).projection as ProjectedFinish;
      expect(projection.date, CalendarDate(2027, 6, 10));
    });

    test('has no rate to project from before anything is saved', () {
      expect(progressOn(CalendarDate(2026, 2, 5), 0).projection, isA<NoRateYet>());
    });

    test('a reached goal needs no projection', () {
      expect(progressOn(CalendarDate(2026, 2, 5), 1200).projection, isA<AlreadyReached>());
    });
  });
}
