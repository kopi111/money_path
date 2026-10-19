import '../domain/calendar/calendar_date.dart';

/// The one place the app asks what time it is, so tests can fix the date.
class Clock {
  const Clock();

  DateTime nowUtc() => DateTime.now().toUtc();

  CalendarDate today() => CalendarDate.fromDateTime(DateTime.now());
}

class FixedClock extends Clock {
  const FixedClock(this.fixedToday);

  final CalendarDate fixedToday;

  @override
  DateTime nowUtc() => DateTime.utc(fixedToday.year, fixedToday.month, fixedToday.day, 12);

  @override
  CalendarDate today() => fixedToday;
}
