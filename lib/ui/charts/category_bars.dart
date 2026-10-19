import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/budget/budget_records.dart';
import '../../domain/money/money.dart';
import '../format/category_icons.dart';
import '../theme/book_palette.dart';
import '../widgets/amount_text.dart';
import '../widgets/ruled_page.dart';

/// Spending by category as horizontal bars, largest first. Every bar carries
/// its own label and amount, so the chart reads without a legend.
class CategoryBars extends ConsumerWidget {
  const CategoryBars({super.key, required this.spentByCategory});

  final Map<String, Money> spentByCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final money = ref.watch(moneyFormatterProvider);
    final rows = spentByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) return const PageText('No spending this month.');
    final largest = rows.first.value;
    final total = Money.sum(rows.map((row) => row.value));
    final book = context.book;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final row in rows)
          Semantics(
            label: '${categories.byId(row.key).name}: ${money.formatShort(row.value)}, '
                '${row.value.percentOf(total)} percent of spending',
            excludeSemantics: true,
            child: Padding(
              padding: RuledPage.writingInset.copyWith(top: 6, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CategoryIcons.of(categories.byId(row.key).iconName), size: 18, color: book.inkSoft),
                      const SizedBox(width: 8),
                      Expanded(child: Text(categories.byId(row.key).name, style: text.bodyLarge)),
                      Text('${row.value.percentOf(total)}%  ', style: text.bodySmall?.copyWith(color: book.inkSoft)),
                      AmountText(row.value, size: AmountSize.small),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, constraints) => Container(
                      height: 12,
                      width: constraints.maxWidth * row.value.cents / largest.cents,
                      decoration: BoxDecoration(color: book.ink, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
