import 'calendar_date.dart';

/// One budget month, e.g. October 2026.
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month);

  factory YearMonth.of(CalendarDate date) => YearMonth(date.year, date.month);

  /// Parses the stored form "2026-10".
  factory YearMonth.parse(String key) {
    final parts = key.split('-');
    return YearMonth(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int year;
  final int month;

  CalendarDate get firstDay => CalendarDate(year, month, 1);
  CalendarDate get lastDay =>
      CalendarDate(year, month, CalendarDate.daysInMonth(year, month));

  YearMonth get next => YearMonth.of(firstDay.addMonths(1));
  YearMonth get previous => YearMonth.of(firstDay.addMonths(-1));

  bool contains(CalendarDate date) => date.year == year && date.month == month;

  /// The given day of this month, or the month's last day when it is shorter.
  CalendarDate dayOrLast(int day) {
    final lastDayNumber = CalendarDate.daysInMonth(year, month);
    return CalendarDate(year, month, day > lastDayNumber ? lastDayNumber : day);
  }

  String get key => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  @override
  int compareTo(YearMonth other) =>
      (year * 12 + month).compareTo(other.year * 12 + other.month);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}
