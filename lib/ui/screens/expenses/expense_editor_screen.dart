import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_services.dart';
import '../../../app/providers.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/calendar/calendar_date.dart';
import '../../../domain/money/money.dart';
import '../../../services/receipt_camera.dart';
import '../../format/dates.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/money_field.dart';
import '../../widgets/ruled_page.dart';

const _groceriesId = '00000000-0000-4000-8000-000000000001';

class ExpenseEditorScreen extends ConsumerStatefulWidget {
  const ExpenseEditorScreen({super.key, this.existing, this.startingAmount = Money.zero});

  static Route<void> route({Expense? existing, Money startingAmount = Money.zero}) => MaterialPageRoute(
        builder: (_) => ExpenseEditorScreen(existing: existing, startingAmount: startingAmount),
      );

  final Expense? existing;
  final Money startingAmount;

  @override
  ConsumerState<ExpenseEditorScreen> createState() => _ExpenseEditorScreenState();
}

class _ExpenseEditorScreenState extends ConsumerState<ExpenseEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late CalendarDate _date;
  String _categoryId = _groceriesId;
  Receipt _receipt = const NoReceipt();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final money = ref.read(moneyFormatterProvider);
    _date = ref.read(todayProvider);
    if (widget.startingAmount.isPositive) _amount.text = money.formatForEditing(widget.startingAmount);
    final existing = widget.existing;
    if (existing == null) return;
    _amount.text = money.formatForEditing(existing.amount);
    _note.text = existing.note;
    _date = existing.date;
    _categoryId = existing.categoryId;
    _receipt = existing.receipt;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  ReceiptCamera get _camera => ReceiptCamera(ref.read(appServicesProvider).session.receiptsFolder);

  Future<void> _attach(ReceiptSource source) async {
    try {
      final receipt = await _camera.capture(source);
      if (receipt is ReceiptPhoto) setState(() => _receipt = receipt);
    } on ReceiptUnavailable catch (problem) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No photo: $problem')));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toLocalDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = CalendarDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final draft = ExpenseDraft(
      amount: MoneyField.read(_amount),
      categoryId: _categoryId,
      date: _date,
      note: _note.text.trim(),
      receipt: _receipt,
    );
    final repository = ref.read(budgetRepositoryProvider);
    final existing = widget.existing;
    if (existing == null) {
      await repository.addExpense(draft);
    } else {
      await repository.updateExpense(existing.id, draft);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing!;
    final repository = ref.read(budgetRepositoryProvider);
    await repository.deleteExpense(existing.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: const Text('Expense deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => repository.addExpense(ExpenseDraft(
          amount: existing.amount,
          categoryId: existing.categoryId,
          date: existing.date,
          note: existing.note,
          receipt: existing.receipt,
        )),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Change expense' : 'New expense'),
          actions: [
            if (_isEditing) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline), tooltip: 'Delete'),
          ],
        ),
        body: RuledPage(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: RuledPage.writingInset.copyWith(top: 8),
                  child: MoneyField(controller: _amount, label: 'Amount'),
                ),
                const PageHeading('What for'),
                Padding(
                  padding: RuledPage.writingInset,
                  child: CategoryPicker(selectedId: _categoryId, onChanged: (id) => setState(() => _categoryId = id)),
                ),
                const SizedBox(height: 12),
                LedgerRow(
                  title: 'Date',
                  subtitle: Dates.dayMonthYear(_date),
                  amount: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
                ),
                Padding(
                  padding: RuledPage.writingInset.copyWith(top: 8),
                  child: TextFormField(
                    controller: _note,
                    decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Hi-Lo, weekly shop'),
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const PageHeading('Receipt'),
                _ReceiptArea(
                  receipt: _receipt,
                  onCamera: () => _attach(ReceiptSource.camera),
                  onGallery: () => _attach(ReceiptSource.gallery),
                  onRemove: () => setState(() => _receipt = const NoReceipt()),
                ),
                Padding(
                  padding: RuledPage.writingInset.copyWith(top: 24),
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    child: Text(_isEditing ? 'Save changes' : 'Save expense'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ReceiptArea extends StatelessWidget {
  const _ReceiptArea({required this.receipt, required this.onCamera, required this.onGallery, required this.onRemove});

  final Receipt receipt;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Padding(
        padding: RuledPage.writingInset,
        child: switch (receipt) {
          ReceiptPhoto(:final path) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(
                    File(path),
                    height: 220,
                    fit: BoxFit.cover,
                    semanticLabel: 'Receipt photo',
                    errorBuilder: (_, _, _) => const Text('The photo file is missing.'),
                  ),
                ),
                TextButton.icon(onPressed: onRemove, icon: const Icon(Icons.close), label: const Text('Remove photo')),
              ],
            ),
          NoReceipt() => Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(onPressed: onCamera, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Take photo')),
                OutlinedButton.icon(onPressed: onGallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('From gallery')),
              ],
            ),
        },
      );
}
