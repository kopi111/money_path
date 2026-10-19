import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/money/money.dart';
import '../../domain/money/money_parser.dart';
import '../theme/book_palette.dart';

/// What has been typed on the keypad so far, kept as text so "12." survives
/// until the next digit arrives.
class KeypadEntry {
  const KeypadEntry([this.typed = '']);

  static const _maxDollarDigits = 9;

  final String typed;

  Money get amount => typed.isEmpty ? Money.zero : const MoneyParser().parse(typed);

  KeypadEntry press(String key) {
    if (key == '.') return typed.contains('.') ? this : KeypadEntry(typed.isEmpty ? '0.' : '$typed.');
    final parts = typed.split('.');
    if (parts.length == 2 && parts[1].length >= 2) return this;
    if (parts.length == 1 && parts[0].length >= _maxDollarDigits) return this;
    if (typed == '0') return KeypadEntry(key);
    return KeypadEntry('$typed$key');
  }

  KeypadEntry backspace() => typed.isEmpty ? this : KeypadEntry(typed.substring(0, typed.length - 1));
}

/// A big-key number pad for one-handed entry at the bottom of the screen.
class MoneyKeypad extends StatelessWidget {
  const MoneyKeypad({super.key, required this.onKey, required this.onBackspace});

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Row(children: [for (final key in row) Expanded(child: _key(context, key))]),
        ],
      );

  Widget _key(BuildContext context, String key) {
    final book = context.book;
    final isBackspace = key == '⌫';
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: 56,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: book.ink,
            backgroundColor: book.rule.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            isBackspace ? onBackspace() : onKey(key);
          },
          onLongPress: isBackspace ? onBackspace : null,
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, semanticLabel: 'Delete last digit')
              : Text(key == '.' ? '.' : key,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  semanticsLabel: key == '.' ? 'point' : key),
        ),
      ),
    );
  }
}
