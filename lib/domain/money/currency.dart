/// The currency amounts are shown in. Amounts are always stored in cents;
/// the currency only changes how they are written.
class Currency {
  const Currency({required this.code, required this.symbol, required this.name});

  final String code;
  final String symbol;
  final String name;

  static const jamaicanDollar =
      Currency(code: 'JMD', symbol: r'$', name: 'Jamaican dollar');

  static const supported = [
    jamaicanDollar,
    Currency(code: 'USD', symbol: r'US$', name: 'US dollar'),
    Currency(code: 'CAD', symbol: r'CA$', name: 'Canadian dollar'),
    Currency(code: 'GBP', symbol: '£', name: 'Pound sterling'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
  ];

  static Currency fromCode(String code) => supported.firstWhere(
        (currency) => currency.code == code,
        orElse: () => jamaicanDollar,
      );

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
