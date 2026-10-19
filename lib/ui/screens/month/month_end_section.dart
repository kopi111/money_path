import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/calendar/year_month.dart';
import '../../format/dates.dart';
import '../../theme/book_palette.dart';
import '../../widgets/ruled_page.dart';

/// At month end, the leftover can go on to next month or into a goal.
class MonthEndSection extends ConsumerWidget {
  const MonthEndSection({super.key, required this.data});

  static const _daysBeforeEndToOffer = 5;

  final MonthSnapshot data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = data.ledger.month;
    final money = ref.watch(moneyFormatterProvider);
    return switch (data.monthEnd) {
      LeftoverMoved(:final closing) => PageText(
          closing.destination == LeftoverDestination.nextMonth
              ? '${money.formatShort(closing.leftover)} left over was carried to ${Dates.monthName(month.next)}.'
              : '${money.formatShort(closing.leftover)} left over went into ${closing.goalName}.',
        ),
      MonthStillOpen() when _canClose(ref, month) && data.ledger.leftover.isPositive =>
        _LeftoverChoice(data: data),
      MonthStillOpen() => const SizedBox.shrink(),
    };
  }

  bool _canClose(WidgetRef ref, YearMonth month) {
    final today = ref.watch(todayProvider);
    return today.isAfter(month.lastDay) || month.lastDay.addDays(-_daysBeforeEndToOffer).isBefore(today);
  }
}

class _LeftoverChoice extends ConsumerWidget {
  const _LeftoverChoice({required this.data});

  final MonthSnapshot data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = data.ledger.month;
    final money = ref.watch(moneyFormatterProvider);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: RuledPage.writingInset.copyWith(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${money.formatShort(data.ledger.leftover)} left over in ${Dates.monthName(month)}',
              style: text.titleMedium),
          const SizedBox(height: 4),
          Text('Move it on so this month closes at zero.',
              style: text.bodyMedium?.copyWith(color: context.book.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => ref
                    .read(budgetRepositoryProvider)
                    .carryLeftoverToNextMonth(month, monthName: Dates.monthName(month)),
                child: Text('Carry to ${Dates.monthName(month.next)}'),
              ),
              OutlinedButton(
                onPressed: () => _chooseGoal(context, ref),
                child: const Text('Put into a goal'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _chooseGoal(BuildContext context, WidgetRef ref) async {
    final goals = (ref.read(goalViewsProvider).valueOrNull ?? const <GoalView>[])
        .where((view) => view.record.goal.isOpen)
        .toList();
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Which goal?'),
        children: [
          if (goals.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('Start a goal first.')),
          for (final view in goals)
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              onPressed: () => Navigator.pop(context, view.record.goal.id),
              child: Text(view.record.goal.name),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    final month = data.ledger.month;
    await ref.read(budgetRepositoryProvider).moveLeftoverToGoal(month, goalId: chosen, monthName: Dates.monthName(month));
  }
}
