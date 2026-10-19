import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/repositories/budget_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../domain/budget/budget_records.dart';
import '../domain/calendar/calendar_date.dart';
import '../domain/calendar/year_month.dart';
import '../domain/goals/goal_entry.dart';
import '../domain/money/money.dart';
import '../domain/money/money_formatter.dart';

/// Writes the owner's records to CSV or PDF and hands them to the share sheet.
/// Nothing is sent anywhere unless the owner picks a destination.
class ExportService {
  ExportService({required this.budget, required this.goals, required this.money});

  final BudgetRepository budget;
  final GoalRepository goals;
  final MoneyFormatter money;

  static final _earliest = CalendarDate(2000, 1, 1);
  static final _latest = CalendarDate(2100, 12, 31);

  Future<void> shareCsv(List<Category> categories) async {
    final csv = await buildCsv(categories);
    final file = await _tempFile('money-path-records.csv');
    await file.writeAsString(csv);
    await _share(file, 'Money Path records');
  }

  Future<String> buildCsv(List<Category> categories) async {
    final names = {for (final category in categories) category.id: category.name};
    final expenses = await budget.expensesBetween(_earliest, _latest);
    final records = await goals.loadAll();
    final incomes = await budget.allIncomes();
    final rows = <List<String>>[
      for (final expense in expenses)
        [expense.date.toIso(), 'Expense', names[expense.categoryId] ?? '', _plain(expense.amount), expense.note],
      for (final record in records)
        for (final entry in record.entries)
          [
            entry.date.toIso(),
            entry.kind == GoalEntryKind.deposit ? 'Goal deposit' : 'Goal withdrawal',
            record.goal.name,
            _plain(entry.amount),
            entry.note,
          ],
      for (final income in incomes)
        [income.receivedOn.toIso(), 'Income', income.source, _plain(income.amount), ''],
    ]..sort((a, b) => a.first.compareTo(b.first));
    const header = ['Date', 'Type', 'Category or goal', 'Amount', 'Note'];
    return [header, ...rows].map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  Future<void> shareMonthPdf(YearMonth month, String monthTitle, List<Category> categories) async {
    final snapshot = await budget.loadMonth(month);
    final document = _monthReport(snapshot, monthTitle, categories, await _pdfTheme());
    final file = await _tempFile('money-path-${month.key}.pdf');
    await file.writeAsBytes(await document.save());
    await _share(file, 'Money Path, $monthTitle');
  }

  /// Helvetica has no minus sign or pound sign, so the app's own face is embedded.
  Future<pw.ThemeData> _pdfTheme() async => pw.ThemeData.withFont(
        base: pw.Font.ttf(await rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-Regular.ttf')),
        bold: pw.Font.ttf(await rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-Bold.ttf')),
      );

  pw.Document _monthReport(MonthSnapshot snapshot, String monthTitle, List<Category> categories, pw.ThemeData theme) {
    final ledger = snapshot.ledger;
    final names = {for (final category in categories) category.id: category.name};
    final byCategory = ledger.spentByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final document = pw.Document(title: 'Money Path, $monthTitle', author: 'Money Path');
    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      build: (context) => [
        pw.Header(level: 0, text: 'Money Path: $monthTitle'),
        _table(['', 'Amount'], [
          ['Income', money.format(ledger.income)],
          ['Expenses', money.format(ledger.spent)],
          ['Saved into goals', money.format(ledger.savedToGoals)],
          ['Left over', money.format(ledger.leftover)],
        ]),
        pw.SizedBox(height: 18),
        pw.Header(level: 1, text: 'Spending by category'),
        _table(['Category', 'Amount'], [
          for (final entry in byCategory) [names[entry.key] ?? 'Unknown', money.format(entry.value)],
        ]),
        pw.SizedBox(height: 18),
        pw.Header(level: 1, text: 'Every expense'),
        _table(['Date', 'Category', 'Note', 'Amount'], [
          for (final expense in snapshot.expenses)
            [expense.date.toIso(), names[expense.categoryId] ?? '', expense.note, money.format(expense.amount)],
        ]),
      ],
    ));
    return document;
  }

  pw.Widget _table(List<String> headers, List<List<String>> rows) => pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        cellAlignments: {headers.length - 1: pw.Alignment.centerRight},
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey400)),
      );

  Future<File> _tempFile(String name) async {
    final folder = await getTemporaryDirectory();
    return File(p.join(folder.path, name));
  }

  Future<void> _share(File file, String subject) =>
      SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: subject));

  /// Plain digits with a decimal point, so spreadsheets read it as a number.
  String _plain(Money amount) =>
      '${amount.cents ~/ Money.centsPerDollar}.${(amount.cents % Money.centsPerDollar).toString().padLeft(2, '0')}';
}

String _csvCell(String value) {
  final needsQuotes = value.contains(RegExp(r'[",\r\n]')) || value.startsWith(RegExp(r'[=+\-@]'));
  final guarded = value.startsWith(RegExp(r'[=+\-@]')) ? "'$value" : value;
  return needsQuotes ? '"${guarded.replaceAll('"', '""')}"' : guarded;
}
