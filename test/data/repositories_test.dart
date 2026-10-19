import 'package:flutter_test/flutter_test.dart';
import 'package:money_path/core/clock.dart';
import 'package:money_path/data/app_database.dart';
import 'package:money_path/data/repositories/bill_repository.dart';
import 'package:money_path/data/repositories/budget_repository.dart';
import 'package:money_path/data/repositories/category_repository.dart';
import 'package:money_path/data/repositories/goal_repository.dart';
import 'package:money_path/domain/budget/budget_records.dart';
import 'package:money_path/domain/calendar/calendar_date.dart';
import 'package:money_path/domain/calendar/year_month.dart';
import 'package:money_path/domain/goals/contribution_frequency.dart';
import 'package:money_path/domain/goals/goal_entry.dart';
import 'package:money_path/domain/money/money.dart';

import 'test_database.dart';

const october = YearMonth(2026, 10);
const groceriesId = '00000000-0000-4000-8000-000000000001';
const rentId = '00000000-0000-4000-8000-000000000002';

void main() {
  late AppDatabase database;
  late BudgetRepository budget;
  late GoalRepository goals;
  late BillRepository bills;
  final today = CalendarDate(2026, 10, 15);

  setUp(() {
    database = openTestDatabase();
    budget = BudgetRepository(database, clock: FixedClock(today));
    goals = GoalRepository(database, clock: FixedClock(today));
    bills = BillRepository(database, clock: FixedClock(today));
  });

  tearDown(() => database.close());

  Future<String> carFund() => goals.create(GoalDraft(
        name: 'Car fund',
        target: Money.dollars(500000),
        start: CalendarDate(2026, 1, 1),
        end: CalendarDate(2027, 12, 31),
        frequency: ContributionFrequency.monthly,
      ));

  test('a new install has the starter categories', () async {
    final categories = await CategoryRepository(database).loadAll();
    expect(categories.first.name, 'Groceries');
  });

  test('income less expenses less goal deposits is what remains', () async {
    final goalId = await carFund();
    await budget.addIncome(month: october, source: 'October pay', amount: Money.dollars(150000));
    await budget.addExpense(ExpenseDraft(amount: Money.dollars(12000), categoryId: groceriesId, date: today));
    await goals.addEntry(goalId: goalId, kind: GoalEntryKind.deposit, amount: Money.dollars(20000), date: today);
    final snapshot = await budget.loadMonth(october);
    expect(snapshot.ledger.remaining, Money.dollars(118000));
  });

  test('a deleted expense no longer counts', () async {
    await budget.addIncome(month: october, source: 'Pay', amount: Money.dollars(1000));
    final id = await budget.addExpense(ExpenseDraft(amount: Money.dollars(300), categoryId: groceriesId, date: today));
    await budget.deleteExpense(id);
    expect((await budget.loadMonth(october)).ledger.remaining, Money.dollars(1000));
  });

  test('recurring bills post once per month however often posting runs', () async {
    await bills.create(BillDraft(name: 'Rent', amount: Money.dollars(60000), categoryId: rentId, dueDay: 1));
    expect(await bills.postDueBills(october), 1);
    expect(await bills.postDueBills(october), 0);
    expect((await budget.loadMonth(october)).ledger.spent, Money.dollars(60000));
  });

  test('carrying leftover forward empties this month and funds next month', () async {
    await budget.addIncome(month: october, source: 'Pay', amount: Money.dollars(1000));
    await budget.carryLeftoverToNextMonth(october, monthName: 'October');
    expect((await budget.loadMonth(october)).ledger.remaining, Money.zero);
    expect((await budget.loadMonth(october.next)).ledger.income, Money.dollars(1000));
  });

  test('moving leftover into a goal deposits it and empties the month', () async {
    final goalId = await carFund();
    await budget.addIncome(month: october, source: 'Pay', amount: Money.dollars(1000));
    await budget.moveLeftoverToGoal(october, goalId: goalId, monthName: 'October');
    final saved = (await goals.loadAll()).single.saved;
    expect(saved, Money.dollars(1000));
    expect((await budget.loadMonth(october)).ledger.remaining, Money.zero);
  });

  test('a month\'s leftover can only be moved once', () async {
    await budget.addIncome(month: october, source: 'Pay', amount: Money.dollars(1000));
    await budget.carryLeftoverToNextMonth(october, monthName: 'October');
    expect(() => budget.carryLeftoverToNextMonth(october, monthName: 'October'), throwsStateError);
  });

  test('a withdrawal reduces what the goal holds', () async {
    final goalId = await carFund();
    await goals.addEntry(goalId: goalId, kind: GoalEntryKind.deposit, amount: Money.dollars(500), date: today);
    await goals.addEntry(goalId: goalId, kind: GoalEntryKind.withdrawal, amount: Money.dollars(200), date: today);
    expect((await goals.loadAll()).single.saved, Money.dollars(300));
  });

  test('a category limit is stored and cleared', () async {
    final categories = CategoryRepository(database);
    await categories.setLimit(groceriesId, Money.dollars(15000));
    expect((await categories.loadAll()).first.monthlyLimit, isA<LimitOf>());
    await categories.clearLimit(groceriesId);
    expect((await categories.loadAll()).first.monthlyLimit, isA<NoLimit>());
  });

  test('search finds notes containing the words, including a literal percent sign', () async {
    await budget.addExpense(ExpenseDraft(amount: Money.dollars(50), categoryId: groceriesId, date: today, note: '10% off at Hi-Lo'));
    await budget.addExpense(ExpenseDraft(amount: Money.dollars(70), categoryId: groceriesId, date: today, note: 'Market'));
    final found = await budget.search(ExpenseFilter(from: CalendarDate(2026, 10, 1), to: today, words: '10%'));
    expect(found.map((e) => e.note), ['10% off at Hi-Lo']);
  });

  test('search keeps to the amount range', () async {
    await budget.addExpense(ExpenseDraft(amount: Money.dollars(50), categoryId: groceriesId, date: today));
    await budget.addExpense(ExpenseDraft(amount: Money.dollars(5000), categoryId: rentId, date: today));
    final found = await budget.search(ExpenseFilter(
      from: CalendarDate(2026, 10, 1),
      to: today,
      minimum: Money.dollars(100),
      maximum: Money.dollars(6000),
    ));
    expect(found.single.amount, Money.dollars(5000));
  });
}
