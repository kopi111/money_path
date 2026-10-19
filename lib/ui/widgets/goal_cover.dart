import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/goals/goal.dart';
import '../format/dates.dart';
import '../theme/book_palette.dart';
import 'amount_text.dart';
import 'status_line.dart';

/// A goal drawn as an exercise book: a solid card cover with the white
/// label plate filled in by hand, and the standing written underneath.
class GoalCover extends ConsumerWidget {
  const GoalCover(this.view, {super.key, this.onTap});

  final GoalView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = context.book;
    final goal = view.record.goal;
    final progress = view.progress;
    final money = ref.watch(moneyFormatterProvider);
    final onCover = book.onCover;
    final text = Theme.of(context).textTheme;
    return Material(
      color: book.coverFor(goal.id),
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabelPlate(goal: goal),
              const SizedBox(height: 18),
              FittedAmount(
                child: AmountText(progress.saved, size: AmountSize.hero, colour: onCover),
              ),
              Text(
                'saved of ${money.formatShort(progress.target)} · ${progress.percentComplete}%',
                style: text.titleSmall?.copyWith(color: onCover),
              ),
              const SizedBox(height: 12),
              _CoverProgressBar(percent: progress.percentComplete),
              const SizedBox(height: 14),
              StatusLine(view.standing, onCover: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact cover for lists: name, amount and standing on one band.
class GoalCoverStrip extends StatelessWidget {
  const GoalCoverStrip(this.view, {super.key, this.onTap});

  final GoalView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    final goal = view.record.goal;
    final text = Theme.of(context).textTheme;
    return Material(
      color: book.coverFor(goal.id),
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: text.titleMedium?.copyWith(color: book.onCover, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AmountText(view.progress.saved, size: AmountSize.row, colour: book.onCover),
                ],
              ),
              const SizedBox(height: 6),
              _CoverProgressBar(percent: view.progress.percentComplete, height: 6),
              const SizedBox(height: 8),
              StatusLine(view.standing, onCover: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelPlate extends StatelessWidget {
  const _LabelPlate({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    final text = Theme.of(context).textTheme;
    final labelStyle = text.labelSmall?.copyWith(color: book.inkSoft, letterSpacing: 0.8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(color: book.labelPlate, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlateLine(
            children: [
              Text('NAME', style: labelStyle),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.name,
                  style: text.titleLarge?.copyWith(color: book.onLabelPlate),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _PlateLine(
            children: [
              Text('BY', style: labelStyle),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${Dates.dayMonthYear(goal.schedule.end)} · ${goal.schedule.frequency.label.toLowerCase()}',
                  style: text.bodyMedium?.copyWith(color: book.onLabelPlate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlateLine extends StatelessWidget {
  const _PlateLine({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.book.rule))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: children),
      );
}

class _CoverProgressBar extends StatelessWidget {
  const _CoverProgressBar({required this.percent, this.height = 10});

  final int percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final onCover = context.book.onCover;
    return ExcludeSemantics(
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: onCover, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: percent / 100,
          child: ColoredBox(color: onCover),
        ),
      ),
    );
  }
}
