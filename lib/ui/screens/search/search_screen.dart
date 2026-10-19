import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/calendar/calendar_date.dart';
import '../../../domain/money/money.dart';
import '../../format/category_icons.dart';
import '../../format/dates.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/expense_row.dart';
import '../../widgets/money_field.dart';
import '../../widgets/ruled_page.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const SearchScreen());

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _words = TextEditingController();
  final _minimum = TextEditingController();
  final _maximum = TextEditingController();
  late CalendarDate _from;
  late CalendarDate _to;
  final Set<String> _categories = {};
  List<Expense> _results = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _to = ref.read(todayProvider);
    _from = _to.addMonths(-3);
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _words.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _run);
  }

  Future<void> _run() async {
    final results = await ref.read(budgetRepositoryProvider).search(ExpenseFilter(
          from: _from,
          to: _to,
          categoryIds: Set.of(_categories),
          minimum: MoneyField.read(_minimum),
          maximum: MoneyField.read(_maximum),
          words: _words.text,
        ));
    if (mounted) setState(() => _results = results);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _from.toLocalDateTime(), end: _to.toLocalDateTime()),
    );
    if (picked == null) return;
    setState(() {
      _from = CalendarDate.fromDateTime(picked.start);
      _to = CalendarDate.fromDateTime(picked.end);
    });
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final total = Money.sum(_results.map((expense) => expense.amount));
    return Scaffold(
      appBar: AppBar(title: const Text('Search spending')),
      body: RuledPage(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: RuledPage.writingInset.copyWith(top: 8),
              child: TextField(
                controller: _words,
                decoration: const InputDecoration(labelText: 'Words in the note', prefixIcon: Icon(Icons.search)),
                onChanged: (_) => _changed(),
              ),
            ),
            Padding(
              padding: RuledPage.writingInset.copyWith(top: 8),
              child: Row(
                children: [
                  Expanded(child: MoneyField(controller: _minimum, label: 'From', allowBlank: true, onChanged: (_) => _changed())),
                  const SizedBox(width: 16),
                  Expanded(child: MoneyField(controller: _maximum, label: 'Up to', allowBlank: true, onChanged: (_) => _changed())),
                ],
              ),
            ),
            Padding(
              padding: RuledPage.writingInset.copyWith(top: 12),
              child: OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text('${Dates.dayMonthYear(_from)} – ${Dates.dayMonthYear(_to)}'),
              ),
            ),
            Padding(
              padding: RuledPage.writingInset.copyWith(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    FilterChip(
                      avatar: Icon(CategoryIcons.of(category.iconName), size: 18),
                      label: Text(category.name),
                      selected: _categories.contains(category.id),
                      showCheckmark: false,
                      onSelected: (on) {
                        setState(() => on ? _categories.add(category.id) : _categories.remove(category.id));
                        _run();
                      },
                    ),
                ],
              ),
            ),
            PageHeading(
              '${_results.length} ${_results.length == 1 ? 'expense' : 'expenses'}',
              trailing: AmountText(total, size: AmountSize.row),
            ),
            if (_results.isEmpty) const PageText('Nothing matches. Widen the dates or clear a filter.'),
            for (final expense in _results) ExpenseRow(expense),
          ],
        ),
      ),
    );
  }
}
