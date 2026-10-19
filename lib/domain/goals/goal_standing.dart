import '../calendar/calendar_date.dart';
import '../money/money.dart';

/// The traffic-light reading of a goal. Colour is never the only signal:
/// every standing also has a word and an icon in the UI.
enum StatusLight { green, amber, red, neutral }

/// Where a goal stands today against its plan.
sealed class GoalStanding {
  const GoalStanding();

  StatusLight get light;
}

/// Saved at least everything due up to the end of the current period.
class AheadOfPlan extends GoalStanding {
  const AheadOfPlan(this.ahead);

  final Money ahead;

  @override
  StatusLight get light => StatusLight.green;
}

/// Past periods are covered; part of the current period is still to come.
class CurrentPeriodDue extends GoalStanding {
  const CurrentPeriodDue({required this.due, required this.dueBy});

  final Money due;
  final CalendarDate dueBy;

  @override
  StatusLight get light => StatusLight.green;
}

/// Short of what finished periods required.
class BehindPlan extends GoalStanding {
  const BehindPlan({required this.behind, required this.isSlight});

  final Money behind;

  /// Within the owner's amber threshold.
  final bool isSlight;

  @override
  StatusLight get light => isSlight ? StatusLight.amber : StatusLight.red;
}

/// The end date has passed without reaching the target.
class PastEndDate extends GoalStanding {
  const PastEndDate(this.stillNeeded);

  final Money stillNeeded;

  @override
  StatusLight get light => StatusLight.red;
}

class TargetReached extends GoalStanding {
  const TargetReached();

  @override
  StatusLight get light => StatusLight.green;
}

class NotStartedYet extends GoalStanding {
  const NotStartedYet(this.startsOn);

  final CalendarDate startsOn;

  @override
  StatusLight get light => StatusLight.neutral;
}

class PausedGoal extends GoalStanding {
  const PausedGoal();

  @override
  StatusLight get light => StatusLight.neutral;
}
