import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/money/money.dart';

/// One fixed size ramp for money: the bigger the job a figure does, the
/// bigger it prints. Figures are tabular so columns of amounts line up.
enum AmountSize { hero, large, row, small }

enum AmountStyle { plain, signed }

class AmountText extends ConsumerWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.size = AmountSize.row,
    this.style = AmountStyle.plain,
    this.colour,
  });

  final Money amount;
  final AmountSize size;
  final AmountStyle style;
  final Color? colour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final text = style == AmountStyle.signed ? money.formatSigned(amount) : money.formatShort(amount);
    return Text(
      text,
      style: _styleFor(Theme.of(context).textTheme).copyWith(
        color: colour,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
    );
  }

  TextStyle _styleFor(TextTheme text) => switch (size) {
        AmountSize.hero => text.displayMedium!,
        AmountSize.large => text.headlineMedium!,
        AmountSize.row => text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        AmountSize.small => text.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
      };
}

/// Shrinks a large figure to fit its column instead of wrapping it.
class FittedAmount extends StatelessWidget {
  const FittedAmount({super.key, required this.child, this.alignment = Alignment.centerLeft});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}
