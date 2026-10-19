import 'package:flutter/material.dart';

import '../theme/book_palette.dart';

/// The exercise-book page: a red margin rule down the left. Dates and
/// short notes live in the margin; everything else is written to its right.
class RuledPage extends StatelessWidget {
  const RuledPage({super.key, required this.child});

  static const marginWidth = 56.0;
  static const writingInset = EdgeInsets.only(left: marginWidth + 12, right: 16);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    return ColoredBox(
      color: book.paper,
      child: CustomPaint(
        painter: _MarginRulePainter(book.margin),
        child: child,
      ),
    );
  }
}

class _MarginRulePainter extends CustomPainter {
  _MarginRulePainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour.withValues(alpha: 0.85)
      ..strokeWidth = 1.25;
    const x = RuledPage.marginWidth;
    canvas.drawLine(const Offset(x, 0), Offset(x, size.height), paint);
    canvas.drawLine(const Offset(x + 3, 0), Offset(x + 3, size.height), paint);
  }

  @override
  bool shouldRepaint(_MarginRulePainter oldDelegate) => oldDelegate.colour != colour;
}

/// A heading written on the page, with more room above it than below.
class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: RuledPage.writingInset.copyWith(top: 28, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            ?trailing,
          ],
        ),
      );
}

/// Plain writing on the page, indented past the margin.
class PageText extends StatelessWidget {
  const PageText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: RuledPage.writingInset.copyWith(top: 4, bottom: 4),
        child: Text(
          text,
          style: style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.book.inkSoft),
        ),
      );
}
