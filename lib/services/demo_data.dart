import '../data/repositories/bill_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../domain/calendar/calendar_date.dart';
import '../domain/calendar/year_month.dart';
import '../domain/goals/contribution_frequency.dart';
import '../domain/goals/goal_entry.dart';
import '../domain/money/money.dart';

/// Made-up records for trying the app in a debug build. Every note says "demo".
class DemoData {
  const DemoData({required this.budget, required this.goals, required this.bills, required this.categories});

  final BudgetRepository budget;
  final GoalRepository goals;
  final BillRepository bills;
  final CategoryRepository categories;

  static const _groceries = '00000000-0000-4000-8000-000000000001';
  static const _rent = '00000000-0000-4000-8000-000000000002';
  static const _utilities = '00000000-0000-4000-8000-000000000003';
  static const _transport = '00000000-0000-4000-8000-000000000004';
  static const _phone = '00000000-0000-4000-8000-000000000005';
  static const _eatingOut = '00000000-0000-4000-8000-000000000006';

  Future<void> fill(CalendarDate today) async {
    final month = YearMonth.of(today);
    await _months(month.previous, today, isCurrent: false);
    await _months(month, today, isCurrent: true);
    await bills.create(BillDraft(name: 'Rent', amount: Money.dollars(65000), categoryId: _rent, dueDay: 1));
    await bills.create(BillDraft(name: 'JPS light bill', amount: Money.dollars(9800), categoryId: _utilities, dueDay: 24));
    await bills.create(BillDraft(name: 'Internet', amount: Money.dollars(6500), categoryId: _phone, dueDay: 28));
    await categories.setLimit(_groceries, Money.dollars(30000));
    await categories.setLimit(_eatingOut, Money.dollars(8000));
    await _goals(today);
  }

  Future<void> _months(YearMonth month, CalendarDate today, {required bool isCurrent}) async {
    await budget.addIncome(month: month, source: 'Salary (demo)', amount: Money.dollars(185000));
    final lastDay = isCurrent ? today.day : month.lastDay.day;
    final spends = [
      (2, _groceries, 11850, 'Hi-Lo weekly shop (demo)'),
      (4, _transport, 3200, 'Taxi fares (demo)'),
      (7, _eatingOut, 2400, 'Juici patties (demo)'),
      (9, _groceries, 8640, 'Market (demo)'),
      (12, _transport, 5000, 'Gas (demo)'),
      (15, _eatingOut, 3900, 'Lunch with team (demo)'),
      (16, _groceries, 6380, 'Top-up shop (demo)'),
      (18, _eatingOut, 1500, 'Coffee (demo)'),
      (22, _groceries, 9120, 'Hi-Lo weekly shop (demo)'),
    ];
    for (final (day, category, dollars, note) in spends) {
      if (day > lastDay) continue;
      final extra = isCurrent ? 0 : dollars ~/ 7;
      await budget.addExpense(ExpenseDraft(
        amount: Money.dollars(dollars - extra),
        categoryId: category,
        date: month.dayOrLast(day),
        note: note,
      ));
    }
  }

  Future<void> _goals(CalendarDate today) async {
    final carId = await goals.create(GoalDraft(
      name: 'Car fund',
      target: Money.dollars(600000),
      start: today.addMonths(-5),
      end: today.addMonths(19),
      frequency: ContributionFrequency.monthly,
    ));
    for (var month = 5; month >= 1; month--) {
      await goals.addEntry(
        goalId: carId,
        kind: GoalEntryKind.deposit,
        amount: Money.dollars(month == 1 ? 32000 : 25000),
        date: today.addMonths(-month).addDays(2),
        note: 'Demo deposit',
      );
    }
    final schoolId = await goals.create(GoalDraft(
      name: 'School fees',
      target: Money.dollars(120000),
      start: today.addDays(-70),
      end: today.addDays(110),
      frequency: ContributionFrequency.weekly,
    ));
    for (var week = 10; week >= 3; week--) {
      await goals.addEntry(
        goalId: schoolId,
        kind: GoalEntryKind.deposit,
        amount: Money.dollars(4000),
        date: today.addDays(-7 * week),
        note: 'Demo deposit',
      );
    }
    final christmasId = await goals.create(GoalDraft(
      name: 'Christmas',
      target: Money.dollars(50000),
      start: today.addDays(-40),
      end: CalendarDate(today.year, 12, 20),
      frequency: ContributionFrequency.fortnightly,
    ));
    await goals.addEntry(
      goalId: christmasId,
      kind: GoalEntryKind.deposit,
      amount: Money.dollars(9000),
      date: today.addDays(-20),
      note: 'Demo deposit',
    );
  }
}
