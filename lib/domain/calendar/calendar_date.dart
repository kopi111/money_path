/// A day on the calendar with no time of day and no time zone, so that
/// "periods elapsed" never shifts with daylight saving or UTC offsets.
class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(int year, int month, int day) : _utc = DateTime.utc(year, month, day);

  factory CalendarDate.fromDateTime(DateTime moment) =>
      CalendarDate(moment.year, moment.month, moment.day);

  /// Parses the stored form "2026-09-19".
  factory CalendarDate.parse(String isoDate) =>
      CalendarDate.fromDateTime(DateTime.parse(isoDate));

  final DateTime _utc;

  int get year => _utc.year;
  int get month => _utc.month;
  int get day => _utc.day;

  CalendarDate addDays(int days) =>
      CalendarDate.fromDateTime(_utc.add(Duration(days: days)));

  /// Moves by whole months, keeping the day where the month allows it and
  /// otherwise using the month's last day (31 Jan + 1 month = 28 Feb).
  CalendarDate addMonths(int months) {
    final monthIndex = year * 12 + (month - 1) + months;
    final targetYear = monthIndex ~/ 12;
    final targetMonth = monthIndex % 12 + 1;
    final lastDay = daysInMonth(targetYear, targetMonth);
    return CalendarDate(targetYear, targetMonth, day > lastDay ? lastDay : day);
  }

  int daysUntil(CalendarDate later) => later._utc.difference(_utc).inDays;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;
  bool isAfter(CalendarDate other) => compareTo(other) > 0;
  bool isOnOrBefore(CalendarDate other) => compareTo(other) <= 0;
  bool isOnOrAfter(CalendarDate other) => compareTo(other) >= 0;

  DateTime toLocalDateTime() => DateTime(year, month, day);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${_twoDigits(month)}-${_twoDigits(day)}';

  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  @override
  int compareTo(CalendarDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) => other is CalendarDate && other._utc == _utc;

  @override
  int get hashCode => _utc.hashCode;

  @override
  String toString() => toIso();
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
