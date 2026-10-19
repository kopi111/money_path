import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/budget/budget_records.dart';
import '../format/category_icons.dart';

/// Choose one category from chips.
class CategoryPicker extends ConsumerWidget {
  const CategoryPicker({super.key, required this.selectedId, required this.onChanged});

  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final category in categories)
          ChoiceChip(
            avatar: Icon(CategoryIcons.of(category.iconName), size: 18),
            label: Text(category.name),
            selected: category.id == selectedId,
            onSelected: (_) => onChanged(category.id),
            showCheckmark: false,
          ),
      ],
    );
  }
}
