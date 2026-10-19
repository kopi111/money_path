import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/calendar/year_month.dart';
import '../../../domain/money/money.dart';
import '../../../domain/reports/month_comparison.dart';
import '../../charts/category_bars.dart';
import '../../charts/savings_chart.dart';
import '../../format/dates.dart';
import '../../theme/book_palette.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/ruled_page.dart';
import 'export_section.dart';

final reportMonthProvider = StateProvider<YearMonth>((ref) => YearMonth.of(ref.watch(todayProvider)));

final chartGoalProvider = StateProvider<String>((ref) => '');

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportMonthProvider);
    final current = ref.watch(monthProvider(month)).valueOrNull;
    final previous = ref.watch(monthProvider(month.previous)).valueOrNull;
    return RuledPage(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('Reports · ${Dates.monthYear(month)}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous month',
                onPressed: () => ref.read(reportMonthProvider.notifier).state = month.previous,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next month',
                onPressed: () => ref.read(reportMonthProvider.notifier).state = month.next,
              ),
            ],
          ),
          SliverList.list(children: [
            if (current != null) ...[
              const PageHeading('Month-end summary'),
              _MonthSummary(snapshot: current),
              const PageHeading('Spending by category'),
              CategoryBars(spentByCategory: current.ledger.spentByCategory),
              if (previous != null) ...[
                PageHeading('Against ${Dates.monthName(month.previous)}'),
                ..._comparisons(ref, current, previous),
              ],
            ],
            const PageHeading('Savings over time'),
            const _GoalChart(),
            const PageHeading('Export'),
            ExportSection(month: month),
            const SizedBox(height: 48),
          ]),
        ],
      ),
    );
  }

  Iterable<Widget> _comparisons(WidgetRef ref, MonthSnapshot current, MonthSnapshot previous) sync* {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final monthName = Dates.monthName(previous.ledger.month);
    final categoryIds = {...current.ledger.spentByCategory.keys, ...previous.ledger.spentByCategory.keys};
    yield _ComparisonRow(
      label: 'All spending',
      change: SpendingChange.between(previous: previous.ledger.spent, current: current.ledger.spent),
      previousMonth: monthName,
      amount: current.ledger.spent,
    );
    for (final id in categoryIds) {
      yield _ComparisonRow(
        label: categories.byId(id).name,
        change: SpendingChange.between(previous: previous.ledger.spentIn(id), current: current.ledger.spentIn(id)),
        previousMonth: monthName,
        amount: current.ledger.spentIn(id),
      );
    }
  }
}

class _MonthSummary extends ConsumerWidget {
  const _MonthSummary({required this.snapshot});

  final MonthSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = snapshot.ledger;
    final money = ref.watch(moneyFormatterProvider);
    final moved = switch (snapshot.monthEnd) {
      LeftoverMoved(:final closing) => closing.destination == LeftoverDestination.nextMonth
          ? 'Carried to ${Dates.monthName(ledger.month.next)}'
          : 'Put into ${closing.goalName}',
      MonthStillOpen() => ledger.leftover.isNegative ? 'Overspent' : 'Not moved yet',
    };
    return Column(
      children: [
        LedgerRow(title: 'Income', amount: AmountText(ledger.income)),
        LedgerRow(title: 'Expenses', amount: AmountText(ledger.spent)),
        LedgerRow(title: 'Saved into goals', amount: AmountText(ledger.savedToGoals)),
        LedgerRow(
          title: ledger.leftover.isNegative ? 'Short' : 'Left over',
          subtitle: moved,
          amount: AmountText(ledger.leftover.abs(), size: AmountSize.large),
          semanticLabel: '${ledger.leftover.isNegative ? 'Short' : 'Left over'}: '
              '${money.formatShort(ledger.leftover.abs())}. $moved',
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.change, required this.previousMonth, required this.amount});

  final String label;
  final SpendingChange change;
  final String previousMonth;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    final (words, icon, colour) = switch (change) {
      PercentChange(:final percent) when percent > 0 =>
        ('$percent% more than $previousMonth', Icons.arrow_upward, book.behind),
      PercentChange(:final percent) when percent < 0 =>
        ('${-percent}% less than $previousMonth', Icons.arrow_downward, book.ahead),
      PercentChange() => ('Same as $previousMonth', Icons.drag_handle, book.inkSoft),
      NewThisMonth() => ('Nothing in $previousMonth', Icons.add_circle_outline, book.inkSoft),
      NoSpendingEitherMonth() => ('None either month', Icons.remove, book.inkSoft),
    };
    return LedgerRow(
      leading: Icon(icon, color: colour),
      title: label,
      subtitle: words,
      amount: AmountText(amount, size: AmountSize.small),
    );
  }
}

class _GoalChart extends ConsumerWidget {
  const _GoalChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(goalViewsProvider).valueOrNull ?? const <GoalView>[];
    if (views.isEmpty) return const PageText('Start a goal to see its savings against the plan.');
    final chosenId = ref.watch(chartGoalProvider);
    final chosen = views.firstWhere((view) => view.record.goal.id == chosenId, orElse: () => views.first);
    return Padding(
      padding: RuledPage.writingInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final view in views)
                ChoiceChip(
                  label: Text(view.record.goal.name),
                  selected: view == chosen,
                  onSelected: (_) => ref.read(chartGoalProvider.notifier).state = view.record.goal.id,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SavingsChart(view: chosen),
        ],
      ),
    );
  }
}
