import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/money/money.dart';
import '../../domain/money/money_parser.dart';

/// A text field for an amount of money, checked as it is typed.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.onChanged,
    this.allowBlank = false,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final bool allowBlank;

  static Money read(TextEditingController controller) {
    try {
      return const MoneyParser().parse(controller.text);
    } on FormatException {
      return Money.zero;
    }
  }

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, helperText: helper, prefixText: r'$ '),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        onChanged: onChanged,
        validator: _validate,
      );

  String? _validate(String? value) {
    if ((value ?? '').trim().isEmpty) return allowBlank ? null : 'Type an amount';
    try {
      final amount = const MoneyParser().parse(value!);
      return amount.isPositive ? null : 'The amount must be more than zero';
    } on FormatException {
      return 'Write the amount like 1500 or 1500.50';
    }
  }
}
