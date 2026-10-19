import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/book_palette.dart';

/// PIN dots plus a large keypad. Reports the PIN once [length] digits are in.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onComplete,
    this.length = 4,
    this.extraKey,
  });

  final int length;
  final Future<void> Function(String pin) onComplete;

  /// Shown bottom-left, e.g. the fingerprint button.
  final Widget? extraKey;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';
  bool _busy = false;

  Future<void> _press(String digit) async {
    if (_busy || _digits.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() => _digits += digit);
    if (_digits.length == widget.length) {
      _busy = true;
      await widget.onComplete(_digits);
      if (mounted) setState(() => _digits = '');
      _busy = false;
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '${_digits.length} of ${widget.length} digits entered',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < widget.length; index++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _digits.length ? book.ink : Colors.transparent,
                    border: Border.all(color: book.ink, width: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          _row(row.map(_digitKey).toList()),
        _row([
          widget.extraKey ?? const SizedBox.shrink(),
          _digitKey('0'),
          IconButton(
            onPressed: _backspace,
            icon: const Icon(Icons.backspace_outlined, semanticLabel: 'Delete last digit'),
            iconSize: 28,
          ),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> keys) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [for (final key in keys) SizedBox(width: 96, height: 72, child: Center(child: key))],
      );

  Widget _digitKey(String digit) => SizedBox(
        width: 72,
        height: 64,
        child: TextButton(
          onPressed: () => _press(digit),
          style: TextButton.styleFrom(shape: const CircleBorder()),
          child: Text(digit, style: Theme.of(context).textTheme.headlineMedium),
        ),
      );
}
