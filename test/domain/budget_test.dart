import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/domain/budget/category_limit.dart';
import 'package:money_path/domain/budget/month_ledger.dart';
import 'package:money_path/domain/budget/recurring_bill.dart';
import 'package:money_path/domain/calendar/calendar_date.dart';
import 'package:money_path/domain/calendar/year_month.dart';
import 'package:money_path/domain/money/money.dart';

MonthLedger october({int deposits = 0, int withdrawals = 0, int carriedOut = 0}) => MonthLedger(
      month: const YearMonth(2026, 10),
      income: Money.dollars(150000),
      spending: [
        SpendingLine(categoryId: 'groceries', amount: Money.dollars(12000)),
        SpendingLine(categoryId: 'groceries', amount: Money.dollars(3500)),
        SpendingLine(categoryId: 'rent', amount: Money.dollars(60000)),
      ],
      goalDeposits: Money.dollars(deposits),
      goalWithdrawals: Money.dollars(withdrawals),
      carriedOut: Money.dollars(carriedOut),
    );

RecurringBill bill(String id, int dueDay) => RecurringBill(
      id: id,
      name: id,
      amount: Money.dollars(5000),
      categoryId: 'utilities',
      dueDay: dueDay,
    );

void main() {
  group('MonthLedger', () {
    test('every expense comes off the month\'s balance', () {
      expect(october().remaining, Money.dollars(74500));
    });

    test('a goal deposit is money out of the month', () {
      expect(october(deposits: 10000).remaining, Money.dollars(64500));
    });

    test('a goal withdrawal comes back into the month', () {
      expect(october(deposits: 10000, withdrawals: 4000).remaining, Money.dollars(68500));
    });

    test('carrying leftover forward empties the month but keeps the leftover on record', () {
      final ledger = october(carriedOut: 74500);
      expect(ledger.remaining, Money.zero);
      expect(ledger.leftover, Money.dollars(74500));
    });

    test('totals spending per category', () {
      expect(october().spentIn('groceries'), Money.dollars(15500));
    });

    test('a category with no spending has spent nothing', () {
      expect(october().spentIn('transport'), Money.zero);
    });
  });

  group('CategoryLimitCheck', () {
    CategoryLimitCheck groceries(int spent) =>
        CategoryLimitCheck(spent: Money.dollars(spent), limit: Money.dollars(15000));

    test('under 80% is comfortable', () {
      expect(groceries(11999).level, LimitLevel.comfortable);
    });

    test('80% exactly is the first warning', () {
      expect(groceries(12000).level, LimitLevel.nearing);
    });

    test('100% exactly is the second warning', () {
      expect(groceries(15000).level, LimitLevel.reached);
    });

    test('over the limit shows how far over', () {
      expect(groceries(15500).leftUnderLimit, Money.dollars(-500));
    });
  });

  group('BillCalendar', () {
    test('a bill due on the 31st falls on the last day of a short month', () {
      expect(bill('rent', 31).dueDateIn(const YearMonth(2026, 2)), CalendarDate(2026, 2, 28));
    });

    test('bills already posted this month are not posted again', () {
      final calendar = BillCalendar([bill('rent', 1), bill('light', 15)]);
      expect(calendar.unpostedIn({'rent'}).map((b) => b.id), ['light']);
    });

    test('upcoming bills cross into next month, soonest first', () {
      final calendar = BillCalendar([bill('rent', 1), bill('light', 28)]);
      final upcoming = calendar.upcoming(today: CalendarDate(2026, 9, 25), days: 10);
      expect(upcoming.map((u) => u.bill.id), ['light', 'rent']);
      expect(upcoming.last.daysAway, 6);
    });

    test('a bill already past this month is not upcoming', () {
      final calendar = BillCalendar([bill('rent', 1)]);
      expect(calendar.upcoming(today: CalendarDate(2026, 9, 2), days: 7), isEmpty);
    });
  });
}
