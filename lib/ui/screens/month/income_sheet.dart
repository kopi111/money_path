import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/calendar/year_month.dart';
import '../../format/dates.dart';
import '../../widgets/money_field.dart';

Future<void> showIncomeSheet(BuildContext context, YearMonth month) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _IncomeSheet(month: month),
    );

class _IncomeSheet extends ConsumerStatefulWidget {
  const _IncomeSheet({required this.month});

  final YearMonth month;

  @override
  ConsumerState<_IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends ConsumerState<_IncomeSheet> {
  final _form = GlobalKey<FormState>();
  late final _source = TextEditingController(text: '${Dates.monthName(widget.month)} pay');
  final _amount = TextEditingController();

  @override
  void dispose() {
    _source.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await ref.read(budgetRepositoryProvider).addIncome(
          month: widget.month,
          source: _source.text.trim(),
          amount: MoneyField.read(_amount),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Money in for ${Dates.monthYear(widget.month)}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              MoneyField(controller: _amount, label: 'Amount'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _source,
                decoration: const InputDecoration(labelText: 'Where it came from'),
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => (value ?? '').trim().isEmpty ? 'Say where the money came from' : null,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Add income'),
              ),
            ],
          ),
        ),
      );
}
