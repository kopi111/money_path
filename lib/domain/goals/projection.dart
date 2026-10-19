import '../calendar/calendar_date.dart';

/// When the goal will be reached if saving carries on at the average rate so far.
sealed class Projection {
  const Projection();
}

class ProjectedFinish extends Projection {
  const ProjectedFinish(this.date);

  final CalendarDate date;
}

/// Nothing saved yet, or no time has passed, so there is no rate to project from.
class NoRateYet extends Projection {
  const NoRateYet();
}

class AlreadyReached extends Projection {
  const AlreadyReached();
}
