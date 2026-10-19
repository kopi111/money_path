import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/budget/category_limit.dart';
import '../../../domain/calendar/year_month.dart';
import '../../../domain/money/money.dart';
import '../../format/category_icons.dart';
import '../../format/dates.dart';
import '../../theme/book_palette.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/expense_row.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/ruled_page.dart';
import '../bills/bills_screen.dart';
import 'income_sheet.dart';
import 'limit_sheet.dart';
import 'month_end_section.dart';

final shownMonthProvider = StateProvider<YearMonth>((ref) => YearMonth.of(ref.watch(todayProvider)));

class MonthScreen extends ConsumerWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(shownMonthProvider);
    final snapshot = ref.watch(monthProvider(month));
    return RuledPage(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(Dates.monthYear(month)),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
                onPressed: () => ref.read(shownMonthProvider.notifier).state = month.previous,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
                onPressed: () => ref.read(shownMonthProvider.notifier).state = month.next,
              ),
            ],
          ),
          SliverList.list(
            children: snapshot.when(
              data: (data) => _sections(context, ref, data),
              loading: () => const [SizedBox(height: 200)],
              error: (error, _) => [PageText('Could not read this month: $error')],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(BuildContext context, WidgetRef ref, MonthSnapshot data) => [
        _Summary(data: data),
        MonthEndSection(data: data),
        PageHeading(
          'Money in',
          trailing: TextButton.icon(
            onPressed: () => showIncomeSheet(context, data.ledger.month),
            icon: const Icon(Icons.add),
            label: const Text('Add income'),
          ),
        ),
        if (data.incomes.isEmpty) const PageText('No income written in for this month yet.'),
        for (final income in data.incomes) _IncomeRow(income: income),
        const PageHeading('By category'),
        const PageText('Tap a category to set a monthly limit.'),
        ..._categoryRows(context, ref, data),
        LedgerRow(
          leading: const Icon(Icons.event_repeat),
          title: 'Monthly bills',
          subtitle: 'Rent, light, water and others posted each month',
          amount: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(BillsScreen.route()),
        ),
        const PageHeading('Every expense'),
        if (data.expenses.isEmpty) const PageText('Nothing spent this month.'),
        ..._expensesByDay(data),
        const SizedBox(height: 96),
      ];

  Iterable<Widget> _categoryRows(BuildContext context, WidgetRef ref, MonthSnapshot data) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final shown = categories.where((c) => data.ledger.spentIn(c.id).isPositive || c.monthlyLimit is LimitOf);
    return shown.map((category) => _CategoryRow(category: category, spent: data.ledger.spentIn(category.id)));
  }

  Iterable<Widget> _expensesByDay(MonthSnapshot data) sync* {
    final byDay = groupBy(data.expenses, (Expense expense) => expense.date);
    for (final expenses in byDay.values) {
      for (final (index, expense) in expenses.indexed) {
        yield ExpenseRow(expense, showDate: index == 0);
      }
    }
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.data});

  final MonthSnapshot data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = data.ledger;
    final book = context.book;
    final carried = data.monthEnd;
    return Column(
      children: [
        LedgerRow(title: 'Money in', amount: AmountText(ledger.income)),
        LedgerRow(title: 'Spent', amount: AmountText(-ledger.spent, style: AmountStyle.signed)),
        LedgerRow(
          title: 'Put into goals',
          subtitle: ledger.goalWithdrawals.isPositive ? 'After taking out ${_short(ref, ledger.goalWithdrawals)}' : '',
          amount: AmountText(-ledger.savedToGoals, style: AmountStyle.signed),
        ),
        if (carried is LeftoverMoved && carried.closing.destination == LeftoverDestination.nextMonth)
          LedgerRow(title: 'Carried to next month', amount: AmountText(-ledger.carriedOut, style: AmountStyle.signed)),
        _TotalRow(
          label: ledger.remaining.isNegative ? 'Overspent' : 'Left',
          amount: ledger.remaining,
          colour: ledger.remaining.isNegative ? book.behind : book.ink,
        ),
      ],
    );
  }

  String _short(WidgetRef ref, Money amount) => ref.read(moneyFormatterProvider).formatShort(amount);
}

/// The total sits under a double rule, the way sums are closed in a ledger.
class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.amount, required this.colour});

  final String label;
  final Money amount;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    return Container(
      padding: const EdgeInsets.only(left: RuledPage.marginWidth + 12, right: 16, top: 10, bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: book.ink, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedAmount(
                  alignment: Alignment.centerRight,
                  child: AmountText(amount.abs(), size: AmountSize.large, colour: colour),
                ),
                const SizedBox(height: 2),
                Container(height: 1, width: 120, color: book.ink),
                const SizedBox(height: 2),
                Container(height: 1, width: 120, color: book.ink),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeRow extends ConsumerWidget {
  const _IncomeRow({required this.income});

  final Income income;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LedgerRow(
        marginTop: '${income.receivedOn.day}',
        marginBottom: Dates.shortMonth(income.receivedOn),
        title: income.source,
        subtitle: income.kind == IncomeKind.carriedForward ? 'Carried over' : '',
        amount: AmountText(income.amount),
        onTap: () => _offerDelete(context, ref),
      );

  Future<void> _offerDelete(BuildContext context, WidgetRef ref) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${income.source}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (remove ?? false) await ref.read(budgetRepositoryProvider).deleteIncome(income.id);
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category, required this.spent});

  final Category category;
  final Money spent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = category.monthlyLimit;
    final money = ref.watch(moneyFormatterProvider);
    final book = context.book;
    final check = limit is LimitOf ? CategoryLimitCheck(spent: spent, limit: limit.amount) : null;
    final colour = switch (check?.level) {
      LimitLevel.reached => book.behind,
      LimitLevel.nearing => book.slipping,
      _ => book.ink,
    };
    return LedgerRow(
      leading: Icon(CategoryIcons.of(category.iconName)),
      title: category.name,
      subtitle: check == null
          ? 'No limit'
          : '${check.percentUsed}% of ${money.formatShort(check.limit)}'
              '${check.level == LimitLevel.reached ? ' · limit reached' : check.level == LimitLevel.nearing ? ' · nearly there' : ''}',
      amount: AmountText(spent, colour: colour),
      onTap: () => showLimitSheet(context, category),
    );
  }
}
