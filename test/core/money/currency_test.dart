import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/money/currency.dart';

void main() {
  test('the ruble has two fraction digits and its own symbol', () {
    expect(Currency.rub.code, 'RUB');
    expect(Currency.rub.fractionDigits, 2);
    expect(Currency.rub.displaySymbol, '₽');
  });

  test('the yen has none and the dinar three', () {
    expect(Currency.jpy.fractionDigits, 0);
    expect(Currency.kwd.fractionDigits, 3);
  });

  test('a currency without a common symbol shows its code', () {
    expect(Currency.sar.symbol, isNull);
    expect(Currency.sar.displaySymbol, 'SAR');
  });

  test('every supported currency is listed once, with an upper-case code', () {
    final codes = Currency.values.map((currency) => currency.code).toList();

    expect(codes.toSet(), hasLength(codes.length));
    for (final code in codes) {
      expect(code, matches(RegExp(r'^[A-Z]{3}$')));
    }
  });

  test('is found by its code', () {
    expect(Currency.fromCode('USD'), Currency.usd);
    expect(Currency.tryFromCode('EUR'), Currency.eur);
  });

  test('an unknown or lower-case code is not a currency', () {
    expect(Currency.tryFromCode('XXX'), isNull);
    expect(Currency.tryFromCode('rub'), isNull);
    expect(() => Currency.fromCode('XXX'), throwsArgumentError);
  });

  test('currencies with the same code and digits are equal', () {
    expect(const Currency('RUB', 2), Currency.rub);
    expect(const Currency('RUB', 2).hashCode, Currency.rub.hashCode);
    expect(Currency.rub, isNot(Currency.usd));
  });
}
