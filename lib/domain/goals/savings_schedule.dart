import '../calendar/calendar_date.dart';
import '../money/money.dart';
import 'contribution_frequency.dart';

/// The plan behind a goal: reach [target] between [start] and [end] by paying
/// an equal amount every period.
class SavingsSchedule {
  SavingsSchedule({
    required this.target,
    required this.start,
    required this.end,
    required this.frequency,
  }) {
    if (!target.isPositive) {
      throw ArgumentError.value(target, 'target', 'must be more than zero');
    }
    if (!end.isAfter(start)) {
      throw ArgumentError.value(end, 'end', 'must be after the start date');
    }
  }

  final Money target;
  final CalendarDate start;
  final CalendarDate end;
  final ContributionFrequency frequency;

  late final int totalPeriods = _periodsToCover(frequency);

  Money get requiredPerPeriod => target.instalmentOf(totalPeriods);

  Money get requiredPerWeek => target.instalmentOf(_periodsToCover(ContributionFrequency.weekly));

  Money get requiredPerMonth => target.instalmentOf(_periodsToCover(ContributionFrequency.monthly));

  CalendarDate periodStart(int index) => frequency.advance(start, index);

  /// The last day of the period with this [index]; the final period ends on [end].
  CalendarDate periodEnd(int index) {
    final nextStart = periodStart(index + 1);
    return index >= totalPeriods - 1 || nextStart.isAfter(end) ? end : nextStart.addDays(-1);
  }

  /// Periods whose last day has already gone by on [day].
  int completedPeriodsOn(CalendarDate day) {
    var completed = 0;
    while (completed < totalPeriods && periodEnd(completed).isBefore(day)) {
      completed++;
    }
    return completed;
  }

  bool hasStartedOn(CalendarDate day) => day.isOnOrAfter(start);

  bool hasEndedOn(CalendarDate day) => day.isAfter(end);

  /// What the plan says should be saved once [periods] periods are paid.
  Money expectedAfter(int periods) =>
      Money.smallerOf(target, requiredPerPeriod.times(periods));

  int _periodsToCover(ContributionFrequency unit) {
    var periods = 1;
    while (unit.advance(start, periods).isBefore(end)) {
      periods++;
    }
    return periods;
  }
}
