import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/calendar/calendar_date.dart';
import '../../../domain/goals/contribution_frequency.dart';
import '../../../domain/goals/goal.dart';
import '../../../domain/goals/goal_entry.dart';
import '../../../domain/goals/projection.dart';
import '../../charts/savings_chart.dart';
import '../../format/dates.dart';
import '../../theme/book_palette.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/goal_cover.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/ruled_page.dart';
import 'goal_editor_screen.dart';
import 'goal_entry_sheet.dart';

enum _GoalAction { edit, pause, resume, complete, archive, reopen, delete }

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  static Route<void> route(String goalId) =>
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goalId));

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(goalViewsProvider).valueOrNull ?? const <GoalView>[];
    final matches = views.where((view) => view.record.goal.id == goalId);
    if (matches.isEmpty) return const Scaffold(body: SizedBox.expand());
    final view = matches.first;
    final goal = view.record.goal;
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          PopupMenuButton<_GoalAction>(
            tooltip: 'Goal options',
            onSelected: (action) => _act(context, ref, view, action),
            itemBuilder: (_) => [
              for (final action in _actionsFor(goal))
                PopupMenuItem(value: action, child: Text(_labelOf(action))),
            ],
          ),
        ],
      ),
      body: RuledPage(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(padding: RuledPage.writingInset.copyWith(top: 8), child: GoalCover(view)),
            if (goal.isOpen) _EntryButtons(view: view),
            if (view.progress.isReached && goal.state != GoalState.completed)
              _ReachedNote(onComplete: () => ref.read(goalRepositoryProvider).changeState(goal.id, GoalState.completed)),
            _PlanSection(view: view),
            const PageHeading('Saved against the plan'),
            Padding(padding: RuledPage.writingInset, child: SavingsChart(view: view)),
            const PageHeading('Deposits and withdrawals'),
            if (view.record.entries.isEmpty) const PageText('Nothing put in yet.'),
            for (final entry in view.record.entries) _EntryRow(entry: entry),
          ],
        ),
      ),
    );
  }

  List<_GoalAction> _actionsFor(Goal goal) => switch (goal.state) {
        GoalState.active => [_GoalAction.edit, _GoalAction.pause, _GoalAction.complete, _GoalAction.archive, _GoalAction.delete],
        GoalState.paused => [_GoalAction.edit, _GoalAction.resume, _GoalAction.archive, _GoalAction.delete],
        GoalState.completed || GoalState.archived => [_GoalAction.reopen, _GoalAction.delete],
      };

  String _labelOf(_GoalAction action) => switch (action) {
        _GoalAction.edit => 'Change goal',
        _GoalAction.pause => 'Pause',
        _GoalAction.resume => 'Resume',
        _GoalAction.complete => 'Mark complete',
        _GoalAction.archive => 'Archive',
        _GoalAction.reopen => 'Reopen',
        _GoalAction.delete => 'Delete goal',
      };

  Future<void> _act(BuildContext context, WidgetRef ref, GoalView view, _GoalAction action) async {
    final repository = ref.read(goalRepositoryProvider);
    final id = view.record.goal.id;
    switch (action) {
      case _GoalAction.edit:
        await Navigator.of(context).push(GoalEditorScreen.route(existing: view.record.goal));
      case _GoalAction.pause:
        await repository.changeState(id, GoalState.paused);
      case _GoalAction.resume || _GoalAction.reopen:
        await repository.changeState(id, GoalState.active);
      case _GoalAction.complete:
        await repository.changeState(id, GoalState.completed);
      case _GoalAction.archive:
        await repository.changeState(id, GoalState.archived);
      case _GoalAction.delete:
        if (await _confirmDelete(context, view.record.goal.name)) {
          await repository.delete(id);
          if (context.mounted) Navigator.of(context).pop();
        }
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete $name?'),
          content: const Text('The goal and its deposits disappear from every screen. '
              'Deposits already counted in past months stay counted there.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}

class _EntryButtons extends StatelessWidget {
  const _EntryButtons({required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context) => Padding(
        padding: RuledPage.writingInset.copyWith(top: 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => showGoalEntrySheet(
                  context,
                  goal: view.record.goal,
                  kind: GoalEntryKind.deposit,
                  suggested: view.progress.catchUpPerPeriod,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Put money in'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: view.record.saved.isPositive
                  ? () => showGoalEntrySheet(
                        context,
                        goal: view.record.goal,
                        kind: GoalEntryKind.withdrawal,
                        available: view.record.saved,
                      )
                  : null,
              child: const Text('Take out'),
            ),
          ],
        ),
      );
}

class _ReachedNote extends StatelessWidget {
  const _ReachedNote({required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: RuledPage.writingInset.copyWith(top: 16),
        child: Row(
          children: [
            Icon(Icons.flag, color: context.book.ahead),
            const SizedBox(width: 8),
            Expanded(child: Text('Target reached.', style: Theme.of(context).textTheme.titleMedium)),
            TextButton(onPressed: onComplete, child: const Text('Mark complete')),
          ],
        ),
      );
}

class _PlanSection extends ConsumerWidget {
  const _PlanSection({required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final progress = view.progress;
    final schedule = view.record.goal.schedule;
    final period = schedule.frequency.periodName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading('The plan'),
        LedgerRow(title: 'Every $period', subtitle: 'Your chosen plan', amount: AmountText(schedule.requiredPerPeriod)),
        if (schedule.frequency != ContributionFrequency.weekly)
          LedgerRow(title: 'Per week', amount: AmountText(schedule.requiredPerWeek)),
        if (schedule.frequency != ContributionFrequency.monthly)
          LedgerRow(title: 'Per month', amount: AmountText(schedule.requiredPerMonth)),
        LedgerRow(
          title: 'Still to save',
          subtitle: '${progress.periodsLeft} ${progress.periodsLeft == 1 ? period : '${period}s'} left, '
              'ends ${Dates.dayMonthYear(schedule.end)}',
          amount: AmountText(progress.remaining),
        ),
        if (!progress.isReached) ...[
          const PageHeading('To finish on time'),
          PageText(
            'Save ${money.formatShort(progress.catchUpPerPeriod)} every $period from now on '
            'to reach ${money.formatShort(progress.target)} by ${Dates.dayMonthYear(schedule.end)}.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          PageText(_projectionText(progress.projection, schedule.end)),
        ],
      ],
    );
  }

  String _projectionText(Projection projection, CalendarDate end) => switch (projection) {
        ProjectedFinish(:final date) => date.isAfter(end)
            ? 'At your average pace so far you would finish on ${Dates.dayMonthYear(date)}, '
                '${end.daysUntil(date)} days after the end date.'
            : 'At your average pace so far you would finish on ${Dates.dayMonthYear(date)}, on time.',
        NoRateYet() => 'Once you put money in, this shows when you would finish at your pace.',
        AlreadyReached() => '',
      };
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});

  final GoalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeposit = entry.kind == GoalEntryKind.deposit;
    final book = context.book;
    return LedgerRow(
      marginTop: '${entry.date.day}',
      marginBottom: Dates.shortMonth(entry.date),
      title: isDeposit ? 'Put in' : 'Taken out',
      subtitle: entry.note,
      amount: AmountText(entry.signedAmount, style: AmountStyle.signed, colour: isDeposit ? book.ink : book.behind),
      onTap: () => _offerDelete(context, ref),
    );
  }

  Future<void> _offerDelete(BuildContext context, WidgetRef ref) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this entry?'),
        content: const Text('Use this to fix a mistake. The goal and the month both update.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (remove ?? false) await ref.read(goalRepositoryProvider).deleteEntry(entry.id);
  }
}
