import 'package:intl/intl.dart';

import '../../domain/calendar/calendar_date.dart';
import '../../domain/calendar/year_month.dart';

/// Dates written the Jamaican way: day before month.
class Dates {
  const Dates._();

  static final _dayMonth = DateFormat('d MMM');
  static final _dayMonthYear = DateFormat('d MMM yyyy');
  static final _monthName = DateFormat('MMMM');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _shortMonth = DateFormat('MMM');
  static final _weekday = DateFormat('EEEE');

  static String dayMonth(CalendarDate date) => _dayMonth.format(date.toLocalDateTime());

  static String dayMonthYear(CalendarDate date) => _dayMonthYear.format(date.toLocalDateTime());

  static String shortMonth(CalendarDate date) => _shortMonth.format(date.toLocalDateTime());

  static String weekday(CalendarDate date) => _weekday.format(date.toLocalDateTime());

  static String monthName(YearMonth month) => _monthName.format(month.firstDay.toLocalDateTime());

  static String monthYear(YearMonth month) => _monthYear.format(month.firstDay.toLocalDateTime());

  /// "today", "tomorrow", "in 5 days".
  static String relative(int daysAway) => switch (daysAway) {
        0 => 'today',
        1 => 'tomorrow',
        _ => 'in $daysAway days',
      };
}
