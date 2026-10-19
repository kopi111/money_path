import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/budget/budget_records.dart';
import '../format/category_icons.dart';
import '../format/dates.dart';
import '../screens/expenses/expense_editor_screen.dart';
import 'amount_text.dart';
import 'ledger_row.dart';

/// An expense on the ledger; tap to change or delete it.
class ExpenseRow extends ConsumerWidget {
  const ExpenseRow(this.expense, {super.key, this.showDate = true});

  final Expense expense;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final category = categories.byId(expense.categoryId);
    final money = ref.watch(moneyFormatterProvider);
    final details = [
      if (expense.note.isNotEmpty && expense.note != category.name) expense.note,
      if (expense.isFromBill) expense.date.isAfter(ref.watch(todayProvider)) ? 'Bill, due ${Dates.dayMonth(expense.date)}' : 'Monthly bill',
      if (expense.receipt is ReceiptPhoto) 'Receipt photo',
    ].join(' · ');
    return LedgerRow(
      marginTop: showDate ? '${expense.date.day}' : '',
      marginBottom: showDate ? Dates.shortMonth(expense.date) : '',
      leading: Icon(CategoryIcons.of(category.iconName)),
      title: category.name,
      subtitle: details,
      amount: AmountText(expense.amount),
      semanticLabel: '${category.name}, ${money.formatShort(expense.amount)}, ${Dates.dayMonth(expense.date)}. $details',
      onTap: () => Navigator.of(context).push(ExpenseEditorScreen.route(existing: expense)),
    );
  }
}
