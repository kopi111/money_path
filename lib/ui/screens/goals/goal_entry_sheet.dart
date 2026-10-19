import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/goals/goal.dart';
import '../../../domain/goals/goal_entry.dart';
import '../../../domain/money/money.dart';
import '../../theme/book_palette.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/money_keypad.dart';

Future<void> showGoalEntrySheet(
  BuildContext context, {
  required Goal goal,
  required GoalEntryKind kind,
  Money suggested = Money.zero,
  Money available = Money.zero,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalEntrySheet(goal: goal, kind: kind, suggested: suggested, available: available),
    );

class _GoalEntrySheet extends ConsumerStatefulWidget {
  const _GoalEntrySheet({required this.goal, required this.kind, required this.suggested, required this.available});

  final Goal goal;
  final GoalEntryKind kind;
  final Money suggested;
  final Money available;

  @override
  ConsumerState<_GoalEntrySheet> createState() => _GoalEntrySheetState();
}

class _GoalEntrySheetState extends ConsumerState<_GoalEntrySheet> {
  KeypadEntry _entry = const KeypadEntry();
  final _note = TextEditingController();
  String _problem = '';

  bool get _isDeposit => widget.kind == GoalEntryKind.deposit;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = _entry.amount;
    if (!amount.isPositive) {
      setState(() => _problem = 'Type an amount first.');
      return;
    }
    if (!_isDeposit && amount > widget.available) {
      final money = ref.read(moneyFormatterProvider);
      setState(() => _problem = 'This goal only holds ${money.formatShort(widget.available)}.');
      return;
    }
    await ref.read(goalRepositoryProvider).addEntry(
          goalId: widget.goal.id,
          kind: widget.kind,
          amount: amount,
          date: ref.read(todayProvider),
          note: _note.text.trim(),
        );
    if (!mounted) return;
    final money = ref.read(moneyFormatterProvider);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(_isDeposit
          ? 'Put ${money.formatShort(amount)} into ${widget.goal.name}'
          : 'Took ${money.formatShort(amount)} out of ${widget.goal.name}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyFormatterProvider);
    final book = context.book;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_isDeposit ? 'Put money into ${widget.goal.name}' : 'Take money out of ${widget.goal.name}',
              style: text.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: book.ink, width: 2))),
            child: FittedAmount(
              alignment: Alignment.centerRight,
              child: AmountText(_entry.amount, size: AmountSize.hero),
            ),
          ),
          if (_isDeposit && widget.suggested.isPositive)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _entry = KeypadEntry(money.formatForEditing(widget.suggested))),
                child: Text('Use ${money.formatShort(widget.suggested)}, this period\'s amount'),
              ),
            ),
          if (_problem.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: Text(_problem, style: text.bodyMedium?.copyWith(color: book.behind)),
            ),
          TextField(
            controller: _note,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Note (optional)', counterText: ''),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          MoneyKeypad(
            onKey: (key) => setState(() => _entry = _entry.press(key)),
            onBackspace: () => setState(() => _entry = _entry.backspace()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            child: Text(_isDeposit ? 'Put it in' : 'Take it out'),
          ),
        ],
      ),
    );
  }
}
