import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/budget/category_limit.dart';
import '../../../domain/budget/recurring_bill.dart';
import '../../../domain/calendar/calendar_date.dart';
import '../../../domain/calendar/year_month.dart';
import '../../format/dates.dart';
import '../../home_shell.dart';
import '../../theme/book_palette.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/empty_note.dart';
import '../../widgets/expense_row.dart';
import '../../widgets/goal_cover.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/ruled_page.dart';
import '../goals/goal_detail_screen.dart';
import '../goals/goal_editor_screen.dart';
import '../month/income_sheet.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _goalsShown = 2;
  static const _billDays = 14;
  static const _recentShown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final month = YearMonth.of(today);
    final snapshot = ref.watch(monthProvider(month));
    final goals = ref.watch(goalViewsProvider).valueOrNull ?? const [];
    final openGoals = goals.where((view) => view.record.goal.isOpen).take(_goalsShown).toList();
    final bills = ref.watch(billsProvider).valueOrNull ?? const <RecurringBill>[];
    final upcoming = BillCalendar(bills).upcoming(today: today, days: _billDays);
    return RuledPage(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('${Dates.weekday(today)}, ${Dates.dayMonth(today)}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search spending',
                onPressed: () => Navigator.of(context).push(SearchScreen.route()),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(SettingsScreen.route()),
              ),
            ],
          ),
          SliverList.list(children: [
            ...snapshot.when(
              data: (data) => _monthBalance(context, ref, data, month),
              loading: () => const [SizedBox(height: 160)],
              error: (error, _) => [PageText('Could not read this month: $error')],
            ),
            PageHeading(
              'Goals',
              trailing: TextButton(
                onPressed: () => ref.read(selectedTabProvider.notifier).state = HomeTab.goals,
                child: const Text('All goals'),
              ),
            ),
            if (openGoals.isEmpty)
              EmptyNote(
                message: 'No goals yet. A goal tells you each week whether you are ahead or behind.',
                actionLabel: 'Start a goal',
                onAction: () => Navigator.of(context).push(GoalEditorScreen.route()),
              ),
            for (final view in openGoals)
              Padding(
                padding: RuledPage.writingInset.copyWith(bottom: 8),
                child: GoalCoverStrip(
                  view,
                  onTap: () => Navigator.of(context).push(GoalDetailScreen.route(view.record.goal.id)),
                ),
              ),
            const PageHeading('Bills coming up'),
            if (upcoming.isEmpty)
              const PageText('No bills due in the next two weeks.'),
            for (final bill in upcoming)
              LedgerRow(
                marginTop: '${bill.dueOn.day}',
                marginBottom: Dates.shortMonth(bill.dueOn),
                title: bill.bill.name,
                subtitle: 'Due ${Dates.relative(bill.daysAway)}',
                amount: AmountText(bill.bill.amount),
              ),
            ...snapshot.maybeWhen(
              data: (data) => _recentSpending(data, today),
              orElse: () => const <Widget>[],
            ),
            const SizedBox(height: 96),
          ]),
        ],
      ),
    );
  }

  List<Widget> _monthBalance(BuildContext context, WidgetRef ref, MonthSnapshot data, YearMonth month) {
    if (data.incomes.isEmpty) {
      return [
        const SizedBox(height: 12),
        EmptyNote(
          message: 'Payday? Write in ${Dates.monthName(month)}\'s income to start the month.',
          actionLabel: 'Add income',
          onAction: () => showIncomeSheet(context, month),
        ),
      ];
    }
    return [
      _BalanceBlock(data: data, month: month),
      ..._limitWarnings(ref, data),
    ];
  }

  Iterable<Widget> _limitWarnings(WidgetRef ref, MonthSnapshot data) sync* {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    for (final category in categories) {
      final limit = category.monthlyLimit;
      if (limit is! LimitOf) continue;
      final check = CategoryLimitCheck(spent: data.ledger.spentIn(category.id), limit: limit.amount);
      if (check.level == LimitLevel.comfortable) continue;
      yield _LimitWarning(category: category, check: check);
    }
  }

  List<Widget> _recentSpending(MonthSnapshot data, CalendarDate today) {
    final recent = data.expenses.where((e) => e.date.isOnOrBefore(today)).take(_recentShown).toList();
    return [
      const PageHeading('Latest spending'),
      if (recent.isEmpty) const PageText('Nothing spent this month yet. Tap Spend to write something down.'),
      for (final expense in recent) ExpenseRow(expense),
    ];
  }
}

class _BalanceBlock extends ConsumerWidget {
  const _BalanceBlock({required this.data, required this.month});

  final MonthSnapshot data;
  final YearMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = data.ledger;
    final money = ref.watch(moneyFormatterProvider);
    final book = context.book;
    final text = Theme.of(context).textTheme;
    final overspent = ledger.remaining.isNegative;
    return Semantics(
      container: true,
      label: '${overspent ? 'Overspent' : 'Left for'} ${Dates.monthName(month)}: '
          '${money.formatShort(ledger.remaining.abs())}',
      child: InkWell(
        onTap: () => ref.read(selectedTabProvider.notifier).state = HomeTab.month,
        child: Padding(
          padding: RuledPage.writingInset.copyWith(top: 20, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overspent ? 'Overspent in ${Dates.monthName(month)}' : 'Left for ${Dates.monthName(month)}',
                style: text.titleMedium?.copyWith(color: book.inkSoft),
              ),
              FittedAmount(
                child: AmountText(
                  ledger.remaining.abs(),
                  size: AmountSize.hero,
                  colour: overspent ? book.behind : book.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'of ${money.formatShort(ledger.income)} in · '
                '${money.formatShort(ledger.spent)} spent · '
                '${money.formatShort(ledger.savedToGoals)} to goals',
                style: text.bodyMedium?.copyWith(color: book.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitWarning extends ConsumerWidget {
  const _LimitWarning({required this.category, required this.check});

  final Category category;
  final CategoryLimitCheck check;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final book = context.book;
    final reached = check.level == LimitLevel.reached;
    final colour = reached ? book.behind : book.slipping;
    return Padding(
      padding: RuledPage.writingInset.copyWith(top: 4, bottom: 4),
      child: Row(
        children: [
          Icon(reached ? Icons.report : Icons.error_outline, color: colour, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${category.name}: ${money.formatShort(check.spent)} of ${money.formatShort(check.limit)} '
              '(${check.percentUsed}%)${reached ? ' — limit reached' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colour, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
