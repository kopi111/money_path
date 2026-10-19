import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/budget/budget_records.dart';
import '../format/category_icons.dart';
import '../screens/expenses/expense_editor_screen.dart';
import '../theme/book_palette.dart';
import '../widgets/amount_text.dart';
import '../widgets/money_keypad.dart';

/// Tap Spend, type the amount, tap the category: written down.
Future<void> showQuickAdd(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const QuickAddSheet(),
    );

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  KeypadEntry _entry = const KeypadEntry();
  bool _nudge = false;

  Future<void> _save(Category category) async {
    final amount = _entry.amount;
    if (!amount.isPositive) {
      setState(() => _nudge = true);
      return;
    }
    final repository = ref.read(budgetRepositoryProvider);
    final id = await repository.addExpense(ExpenseDraft(
      amount: amount,
      categoryId: category.id,
      date: ref.read(todayProvider),
    ));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final money = ref.read(moneyFormatterProvider);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text('Spent ${money.formatShort(amount)} on ${category.name}'),
      action: SnackBarAction(label: 'Undo', onPressed: () => repository.deleteExpense(id)),
    ));
  }

  void _openFullForm() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(ExpenseEditorScreen.route(startingAmount: _entry.amount));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final book = context.book;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Spent', style: text.titleLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: _openFullForm,
                icon: const Icon(Icons.notes),
                label: const Text('Add details'),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: book.ink, width: 2))),
            child: Semantics(
              liveRegion: true,
              label: 'Amount',
              child: FittedAmount(
                alignment: Alignment.centerRight,
                child: AmountText(_entry.amount, size: AmountSize.hero),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _nudge && !_entry.amount.isPositive ? 'Type the amount first, then tap what it was for.' : 'Tap what it was for to save it.',
            style: text.bodyMedium?.copyWith(color: _nudge && !_entry.amount.isPositive ? book.behind : book.inkSoft),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final category in categories) _CategoryButton(category, onTap: () => _save(category))],
              ),
            ),
          ),
          const SizedBox(height: 16),
          MoneyKeypad(
            onKey: (key) => setState(() => _entry = _entry.press(key)),
            onBackspace: () => setState(() => _entry = _entry.backspace()),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton(this.category, {required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(CategoryIcons.of(category.iconName), size: 20),
        label: Text(category.name),
        onPressed: onTap,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        tooltip: 'Save as ${category.name}',
      );
}

