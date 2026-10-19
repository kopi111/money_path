import '../calendar/calendar_date.dart';

enum ContributionFrequency {
  weekly('week', 'Weekly'),
  fortnightly('fortnight', 'Fortnightly'),
  monthly('month', 'Monthly');

  const ContributionFrequency(this.periodName, this.label);

  /// "week", "fortnight", "month" — used in "per week".
  final String periodName;
  final String label;

  CalendarDate advance(CalendarDate from, int periods) => switch (this) {
        weekly => from.addDays(7 * periods),
        fortnightly => from.addDays(14 * periods),
        monthly => from.addMonths(periods),
      };
}
