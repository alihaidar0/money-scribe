import 'package:meta/meta.dart';

/// A currency: its ISO 4217 code, how many digits its minor unit has (2 for
/// 1/100, 0 for none, 3 for 1/1000) and, where one is in common use, its
/// symbol. Only the currencies listed in [values] are supported; add one there
/// before using it.
@immutable
final class Currency {
  const new(this.code, this.fractionDigits, {this.symbol})
    : assert(code.length == 3, 'An ISO 4217 code has three letters'),
      assert(
        fractionDigits >= 0 && fractionDigits <= 3,
        'Zero to three digits',
      );

  static const rub = Currency('RUB', 2, symbol: '₽');
  static const usd = Currency('USD', 2, symbol: r'$');
  static const eur = Currency('EUR', 2, symbol: '€');
  static const gbp = Currency('GBP', 2, symbol: '£');
  static const try_ = Currency('TRY', 2, symbol: '₺');
  static const jpy = Currency('JPY', 0, symbol: '¥');
  static const sar = Currency('SAR', 2);
  static const aed = Currency('AED', 2);
  static const egp = Currency('EGP', 2);
  static const kwd = Currency('KWD', 3);

  /// Every supported currency.
  static const List<Currency> values = [
    rub,
    usd,
    eur,
    gbp,
    try_,
    jpy,
    sar,
    aed,
    egp,
    kwd,
  ];

  /// The ISO 4217 code, such as `RUB`.
  final String code;

  /// The number of digits after the decimal point: an amount is stored as a
  /// whole number of `10^-fractionDigits` units.
  final int fractionDigits;

  /// The symbol in common use, or `null` when the code is what people read.
  final String? symbol;

  /// What is shown next to an amount: the symbol, or else the code.
  String get displaySymbol => symbol ?? code;

  /// The supported currency with this [code] (upper case), or `null`.
  static Currency? tryFromCode(String code) {
    for (final currency in values) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  /// The supported currency with this [code]; throws for an unknown one.
  static Currency fromCode(String code) {
    return tryFromCode(code) ??
        (throw ArgumentError.value(
          code,
          'code',
          'is not a supported currency',
        ));
  }

  @override
  bool operator ==(Object other) =>
      other is Currency &&
      other.code == code &&
      other.fractionDigits == fractionDigits;

  @override
  int get hashCode => Object.hash(code, fractionDigits);

  @override
  String toString() => code;
}
