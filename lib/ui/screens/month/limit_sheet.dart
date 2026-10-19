import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/budget/budget_records.dart';
import '../../widgets/money_field.dart';

Future<void> showLimitSheet(BuildContext context, Category category) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LimitSheet(category: category),
    );

class _LimitSheet extends ConsumerStatefulWidget {
  const _LimitSheet({required this.category});

  final Category category;

  @override
  ConsumerState<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends ConsumerState<_LimitSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    final limit = widget.category.monthlyLimit;
    if (limit is LimitOf) _amount.text = ref.read(moneyFormatterProvider).formatForEditing(limit.amount);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await ref.read(categoryRepositoryProvider).setLimit(widget.category.id, MoneyField.read(_amount));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    await ref.read(categoryRepositoryProvider).clearLimit(widget.category.id);
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
              Text('Monthly limit for ${widget.category.name}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('You get a warning at 80% and again at 100%.'),
              const SizedBox(height: 8),
              MoneyField(controller: _amount, label: 'Limit each month'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Save limit'),
              ),
              if (widget.category.monthlyLimit is LimitOf)
                TextButton(onPressed: _remove, child: const Text('No limit for this category')),
            ],
          ),
        ),
      );
}
