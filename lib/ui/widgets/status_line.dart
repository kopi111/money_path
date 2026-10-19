import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/goals/goal_standing.dart';
import '../format/standing_words.dart';
import '../theme/book_palette.dart';

/// A goal's standing as icon + word + dollars, underlined by a rule whose
/// form (solid, dashed, double) repeats the colour's message.
class StatusLine extends ConsumerWidget {
  const StatusLine(this.standing, {super.key, this.onCover = false});

  final GoalStanding standing;

  /// Drawn on a coloured cover: the status sits on a white label so its
  /// colour still reads against any cover.
  final bool onCover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = StandingWords.of(standing, ref.watch(moneyFormatterProvider));
    final book = context.book;
    final colour = book.statusColour(standing.light);
    final text = Theme.of(context).textTheme;
    final line = Semantics(
      label: '${words.headline}. ${words.detail}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(words.icon, color: colour, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: words.headline, style: const TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: '  ·  ${words.detail}'),
                  ]),
                  style: text.titleSmall?.copyWith(color: colour),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          StatusRule(form: words.ruleForm, colour: colour),
        ],
      ),
    );
    if (!onCover) return line;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
      decoration: BoxDecoration(color: book.labelPlate, borderRadius: BorderRadius.circular(8)),
      child: line,
    );
  }
}

class StatusRule extends StatelessWidget {
  const StatusRule({super.key, required this.form, required this.colour, this.width = 96});

  final RuleForm form;
  final Color colour;
  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(width, 6),
        painter: _RulePainter(form, colour),
      );
}

class _RulePainter extends CustomPainter {
  _RulePainter(this.form, this.colour);

  final RuleForm form;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 2;
    switch (form) {
      case RuleForm.solid:
        canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      case RuleForm.dashed:
        for (var x = 0.0; x < size.width; x += 10) {
          canvas.drawLine(Offset(x, size.height / 2), Offset(x + 6, size.height / 2), paint);
        }
      case RuleForm.double:
        canvas.drawLine(const Offset(0, 1), Offset(size.width, 1), paint);
        canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), paint);
    }
  }

  @override
  bool shouldRepaint(_RulePainter oldDelegate) => oldDelegate.form != form || oldDelegate.colour != colour;
}

/// A small filled status mark for lists: the light as a dot with its icon.
class StatusDot extends StatelessWidget {
  const StatusDot(this.standing, {super.key});

  final GoalStanding standing;

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: book.statusColour(standing.light), shape: BoxShape.circle),
      child: Icon(_iconFor(standing.light), size: 18, color: book.onStatus),
    );
  }

  IconData _iconFor(StatusLight light) => switch (light) {
        StatusLight.green => Icons.check,
        StatusLight.amber => Icons.priority_high,
        StatusLight.red => Icons.close,
        StatusLight.neutral => Icons.remove,
      };
}
