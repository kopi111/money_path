import 'package:flutter/material.dart';

import '../theme/book_palette.dart';
import 'ruled_page.dart';

/// An empty section that says what goes here and offers the first step.
class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key, required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: RuledPage.writingInset.copyWith(top: 4, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.book.inkSoft)),
            if (actionLabel != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      );
}
