import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/budget/budget_records.dart';
import '../../../domain/calendar/year_month.dart';
import '../../../services/export_service.dart';
import '../../format/dates.dart';
import '../../widgets/ruled_page.dart';

class ExportSection extends ConsumerWidget {
  const ExportSection({super.key, required this.month});

  final YearMonth month;

  ExportService _service(WidgetRef ref) => ExportService(
        budget: ref.read(budgetRepositoryProvider),
        goals: ref.read(goalRepositoryProvider),
        money: ref.read(moneyFormatterProvider),
      );

  List<Category> _categories(WidgetRef ref) => ref.read(categoriesProvider).valueOrNull ?? const [];

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: RuledPage.writingInset,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files are made on the phone. You choose where they go from the share menu.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _service(ref).shareMonthPdf(month, Dates.monthYear(month), _categories(ref)),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text('${Dates.monthName(month)} as PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _service(ref).shareCsv(_categories(ref)),
                  icon: const Icon(Icons.table_view_outlined),
                  label: const Text('All records as CSV'),
                ),
              ],
            ),
          ],
        ),
      );
}
