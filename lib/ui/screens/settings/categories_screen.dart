import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/budget/budget_records.dart';
import '../../format/category_icons.dart';
import '../../widgets/ledger_row.dart';
import '../../widgets/ruled_page.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const CategoriesScreen());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _NewCategorySheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: RuledPage(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final category in categories)
              LedgerRow(
                leading: Icon(CategoryIcons.of(category.iconName)),
                title: category.name,
                amount: const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewCategorySheet extends ConsumerStatefulWidget {
  const _NewCategorySheet();

  @override
  ConsumerState<_NewCategorySheet> createState() => _NewCategorySheetState();
}

class _NewCategorySheetState extends ConsumerState<_NewCategorySheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _icon = 'other';
  String _problem = '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      await ref.read(categoryRepositoryProvider).add(name: _name.text.trim(), iconName: _icon);
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      setState(() => _problem = 'There is already a category with that name.');
    }
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
              Text('New category', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: 'Name', errorText: _problem.isEmpty ? null : _problem),
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => (value ?? '').trim().isEmpty ? 'Name the category' : null,
              ),
              Wrap(
                spacing: 4,
                children: [
                  for (final entry in CategoryIcons.byName.entries)
                    IconButton(
                      isSelected: _icon == entry.key,
                      onPressed: () => setState(() => _icon = entry.key),
                      icon: Icon(entry.value),
                      tooltip: entry.key,
                      style: IconButton.styleFrom(
                        backgroundColor: _icon == entry.key ? Theme.of(context).colorScheme.outlineVariant : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Add category'),
              ),
            ],
          ),
        ),
      );
}
