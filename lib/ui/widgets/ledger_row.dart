import 'package:flutter/material.dart';

import '../theme/book_palette.dart';
import 'ruled_page.dart';

/// One line of the ledger, sitting on its own rule: a margin note on the
/// left, what it was in the middle, and the amount in the sum column.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.title,
    required this.amount,
    this.marginTop = '',
    this.marginBottom = '',
    this.subtitle = '',
    this.leading,
    this.onTap,
    this.semanticLabel,
  });

  final String title;
  final String subtitle;
  final String marginTop;
  final String marginBottom;
  final Widget amount;
  final Widget? leading;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: book.rule))),
          child: Row(
            children: [
              SizedBox(
                width: RuledPage.marginWidth,
                child: _MarginNote(top: marginTop, bottom: marginBottom),
              ),
              const SizedBox(width: 12),
              if (leading != null) ...[
                IconTheme.merge(data: IconThemeData(color: book.inkSoft, size: 22), child: leading!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: text.bodySmall?.copyWith(color: book.inkSoft),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              amount,
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarginNote extends StatelessWidget {
  const _MarginNote({required this.top, required this.bottom});

  final String top;
  final String bottom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final book = context.book;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (top.isNotEmpty)
          Text(top, style: text.titleMedium?.copyWith(color: book.margin, fontWeight: FontWeight.w700)),
        if (bottom.isNotEmpty) Text(bottom, style: text.labelSmall?.copyWith(color: book.margin)),
      ],
    );
  }
}
