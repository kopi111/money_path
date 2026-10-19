import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/bill_repository.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/budget/recurring_bill.dart';
import '../../../domain/calendar/year_month.dart';
import '../../format/category_icons.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/category_picker.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/money_field.dart';
import '../../widgets/ruled_page.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const BillsScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider).valueOrNull ?? const <RecurringBill>[];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly bills')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add bill'),
      ),
      body: RuledPage(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const PageText('Bills here are written into each month automatically on their due day, '
                'and you get a reminder before each one.'),
            if (bills.isEmpty) const PageText('No bills yet. Add rent, light, water, internet or phone.'),
            for (final bill in bills)
              LedgerRow(
                marginTop: '${bill.dueDay}',
                marginBottom: 'each',
                leading: Icon(CategoryIcons.of(categories.byId(bill.categoryId).iconName)),
                title: bill.name,
                subtitle: 'Due on day ${bill.dueDay} · ${categories.byId(bill.categoryId).name}',
                amount: AmountText(bill.amount),
                onTap: () => _edit(context, ref, bill),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, [RecurringBill? bill]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BillSheet(existing: bill),
    );
    await ref.read(billRepositoryProvider).postDueBills(YearMonth.of(ref.read(todayProvider)));
  }
}

class _BillSheet extends ConsumerStatefulWidget {
  const _BillSheet({this.existing});

  final RecurringBill? existing;

  @override
  ConsumerState<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends ConsumerState<_BillSheet> {
  static const _utilitiesId = '00000000-0000-4000-8000-000000000003';

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _day = TextEditingController(text: '1');
  String _categoryId = _utilitiesId;

  @override
  void initState() {
    super.initState();
    final bill = widget.existing;
    if (bill == null) return;
    _name.text = bill.name;
    _amount.text = ref.read(moneyFormatterProvider).formatForEditing(bill.amount);
    _day.text = '${bill.dueDay}';
    _categoryId = bill.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _day.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final draft = BillDraft(
      name: _name.text.trim(),
      amount: MoneyField.read(_amount),
      categoryId: _categoryId,
      dueDay: int.parse(_day.text),
    );
    final repository = ref.read(billRepositoryProvider);
    final existing = widget.existing;
    if (existing == null) {
      await repository.create(draft);
    } else {
      await repository.update(existing.id, draft);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(billRepositoryProvider).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.existing == null ? 'New monthly bill' : 'Change bill',
                    style: Theme.of(context).textTheme.titleLarge),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Bill', hintText: 'Light bill'),
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => (value ?? '').trim().isEmpty ? 'Name the bill' : null,
                ),
                MoneyField(controller: _amount, label: 'Usual amount'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _day,
                  decoration: const InputDecoration(labelText: 'Due on day of the month', helperText: '1 to 31. Short months use their last day.'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final day = int.tryParse(value ?? '');
                    return day == null || day < 1 || day > 31 ? 'Type a day from 1 to 31' : null;
                  },
                ),
                const SizedBox(height: 16),
                CategoryPicker(selectedId: _categoryId, onChanged: (id) => setState(() => _categoryId = id)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: const Text('Save bill'),
                ),
                if (widget.existing != null)
                  TextButton(onPressed: _delete, child: const Text('Stop this bill')),
              ],
            ),
          ),
        ),
      );
}
