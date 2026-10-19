import '../calendar/calendar_date.dart';
import '../money/money.dart';
import 'goal_standing.dart';
import 'projection.dart';
import 'savings_schedule.dart';

/// Everything the app says about one goal on one day: how much is saved,
/// whether that is on plan, and what to save from now on to finish on time.
class GoalProgress {
  GoalProgress({
    required this.schedule,
    required this.saved,
    required this.today,
    required this.amberThresholdPercent,
  });

  final SavingsSchedule schedule;
  final Money saved;
  final CalendarDate today;

  /// How far behind, as a percent of one period's amount, still counts as amber.
  final int amberThresholdPercent;

  Money get target => schedule.target;

  Money get remaining => Money.largerOf(Money.zero, target - saved);

  bool get isReached => saved >= target;

  /// 0–100, rounded down so 99.6% never shows as done.
  int get percentComplete =>
      saved.isPositive ? Money.smallerOf(saved, target).percentOf(target) : 0;

  int get completedPeriods => schedule.completedPeriodsOn(today);

  /// Due by the end of the finished periods.
  Money get expectedSoFar => schedule.expectedAfter(completedPeriods);

  /// Due by the end of the period running today.
  Money get expectedByPeriodEnd =>
      schedule.expectedAfter(completedPeriods + 1);

  GoalStanding get standing {
    if (isReached) return const TargetReached();
    if (!schedule.hasStartedOn(today)) return NotStartedYet(schedule.start);
    if (schedule.hasEndedOn(today)) return PastEndDate(remaining);
    return _standingWithinPlan();
  }

  GoalStanding _standingWithinPlan() {
    if (saved >= expectedByPeriodEnd) {
      return AheadOfPlan(saved - expectedByPeriodEnd);
    }
    if (saved >= expectedSoFar) {
      return CurrentPeriodDue(
        due: expectedByPeriodEnd - saved,
        dueBy: schedule.periodEnd(completedPeriods),
      );
    }
    final behind = expectedSoFar - saved;
    return BehindPlan(behind: behind, isSlight: _isWithinAmberThreshold(behind));
  }

  bool _isWithinAmberThreshold(Money behind) =>
      behind.cents * 100 <= schedule.requiredPerPeriod.cents * amberThresholdPercent;

  /// Periods still open, counting the one running today.
  int get periodsLeft => schedule.totalPeriods - completedPeriods;

  /// "Save this much per period from now on to still hit your goal on time."
  Money get catchUpPerPeriod {
    if (isReached) return Money.zero;
    if (periodsLeft <= 0) return remaining;
    return remaining.instalmentOf(periodsLeft);
  }

  Projection get projection {
    if (isReached) return const AlreadyReached();
    final daysSaving = schedule.start.daysUntil(today);
    if (!saved.isPositive || daysSaving <= 0) return const NoRateYet();
    final daysToGo = _ceilDivide(remaining.cents * daysSaving, saved.cents);
    return ProjectedFinish(today.addDays(daysToGo));
  }
}

int _ceilDivide(int numerator, int denominator) =>
    (numerator + denominator - 1) ~/ denominator;
