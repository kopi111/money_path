import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/money.dart';
import '../../domain/reports/savings_history.dart';
import '../format/dates.dart';
import '../theme/book_palette.dart';

/// Actual savings against the plan, period by period. The plan is a dashed
/// line and the actual a solid one, so the two differ in form, not just colour.
class SavingsChart extends ConsumerWidget {
  const SavingsChart({super.key, required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final money = ref.watch(moneyFormatterProvider);
    final movements = [
      for (final entry in view.record.entries) DatedAmount(entry.date, entry.signedAmount),
    ];
    final points = SavingsHistory(view.record.goal.schedule).pointsUpTo(today, movements);
    final book = context.book;
    final last = points.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Savings over time chart. On ${Dates.dayMonth(last.date)}: '
              'saved ${money.formatShort(last.actual)}, plan ${money.formatShort(last.expected)}.',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: _ceiling(points),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(y: _ceiling(points), color: book.rule, strokeWidth: 1),
                  ]),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: book.rule, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: MediaQuery.textScalerOf(context).scale(24),
                        interval: 1,
                        getTitlesWidget: (value, meta) => _dateLabel(context, points, value.round()),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: MediaQuery.textScalerOf(context).scale(48),
                        interval: _ceiling(points) / 4,
                        getTitlesWidget: (value, meta) => Text(
                          _axisLabel(money.currency.symbol, value.round()),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: book.inkSoft),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    _line(points.map((p) => p.expected), book.inkSoft, dashed: true),
                    _line(points.map((p) => p.actual), book.ink, dashed: false),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          children: [
            _LegendKey(label: 'Saved', colour: book.ink, dashed: false),
            _LegendKey(label: 'Plan', colour: book.inkSoft, dashed: true),
          ],
        ),
      ],
    );
  }

  /// Dates under the first, middle and last points only, so labels never crowd.
  Widget _dateLabel(BuildContext context, List<SavingsPoint> points, int index) {
    final labelled = {0, points.length ~/ 2, points.length - 1};
    if (index < 0 || index >= points.length || !labelled.contains(index)) return const SizedBox.shrink();
    final isLast = index == points.length - 1;
    final label = Text(
      isLast ? 'Today' : Dates.dayMonth(points[index].date),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.book.inkSoft),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: isLast ? FractionalTranslation(translation: const Offset(-0.5, 0), child: label) : label,
    );
  }

  /// A round top for the axis so the four gridlines land on tidy amounts.
  double _ceiling(List<SavingsPoint> points) {
    final highest = points.fold<int>(
      100,
      (top, point) => [top, point.actual.cents, point.expected.cents].reduce((a, b) => a > b ? a : b),
    );
    const niceSteps = [1, 2, 5];
    for (var power = 100; ; power *= 10) {
      for (final multiple in niceSteps) {
        final step = multiple * power;
        if (step * 4 >= highest) return (step * 4).toDouble();
      }
    }
  }

  LineChartBarData _line(Iterable<Money> values, Color colour, {required bool dashed}) => LineChartBarData(
        spots: [for (final (index, value) in values.indexed) FlSpot(index.toDouble(), value.cents.toDouble())],
        color: colour,
        barWidth: dashed ? 2 : 3,
        dashArray: dashed ? [6, 5] : null,
        isCurved: false,
        dotData: FlDotData(show: !dashed),
      );
}

/// "$20k", "$1.5M": short enough for the axis at any font size.
String _axisLabel(String symbol, int cents) {
  final dollars = cents ~/ Money.centsPerDollar;
  if (dollars >= 1000000) return '$symbol${_trim(dollars / 1000000)}M';
  if (dollars >= 1000) return '$symbol${_trim(dollars / 1000)}k';
  return '$symbol$dollars';
}

String _trim(double value) => value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1);

class _LegendKey extends StatelessWidget {
  const _LegendKey({required this.label, required this.colour, required this.dashed});

  final String label;
  final Color colour;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: dashed
                ? Row(children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 6, height: 2, margin: const EdgeInsets.only(right: 3), color: colour),
                  ])
                : Container(height: 3, color: colour),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}
