import '../calendar/calendar_date.dart';
import '../calendar/year_month.dart';
import '../money/money.dart';

/// A bill that repeats every month on the same day: rent, light, water.
class RecurringBill {
  RecurringBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.dueDay,
  }) {
    if (dueDay < 1 || dueDay > 31) {
      throw ArgumentError.value(dueDay, 'dueDay', 'must be a day of the month');
    }
  }

  final String id;
  final String name;
  final Money amount;
  final String categoryId;
  final int dueDay;

  CalendarDate dueDateIn(YearMonth month) => month.dayOrLast(dueDay);
}

class UpcomingBill {
  const UpcomingBill({required this.bill, required this.dueOn, required this.daysAway});

  final RecurringBill bill;
  final CalendarDate dueOn;
  final int daysAway;
}

/// Decides which bills to post into a month and which are coming up next.
class BillCalendar {
  const BillCalendar(this.bills);

  final List<RecurringBill> bills;

  /// Bills missing from a month, given the ids of bills already posted in it.
  List<RecurringBill> unpostedIn(Set<String> postedBillIds) =>
      bills.where((bill) => !postedBillIds.contains(bill.id)).toList();

  /// Bills falling due from [today] through the next [days] days, soonest first.
  List<UpcomingBill> upcoming({required CalendarDate today, required int days}) {
    final horizon = today.addDays(days);
    final months = [YearMonth.of(today), YearMonth.of(today).next, YearMonth.of(horizon)];
    final dueDates = {
      for (final month in months.toSet())
        for (final bill in bills) (bill, bill.dueDateIn(month)),
    };
    return dueDates
        .where((entry) => entry.$2.isOnOrAfter(today) && entry.$2.isOnOrBefore(horizon))
        .map((entry) => UpcomingBill(bill: entry.$1, dueOn: entry.$2, daysAway: today.daysUntil(entry.$2)))
        .toList()
      ..sort((a, b) => a.dueOn.compareTo(b.dueOn));
  }
}
