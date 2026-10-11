import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/rounding_mode.dart';

Money _rub(int minorUnits) => Money(minorUnits, Currency.rub);

void main() {
  group('adding and subtracting', () {
    test('is exact where doubles are not (0.10 + 0.20 is 0.30)', () {
      expect(_rub(10) + _rub(20), _rub(30));
    });

    test('subtracts and negates', () {
      expect(_rub(500) - _rub(750), _rub(-250));
      expect(-_rub(500), _rub(-500));
      expect(_rub(-500).abs(), _rub(500));
    });

    test('multiplies by a whole number', () {
      expect(_rub(1234) * 3, _rub(3702));
      expect(_rub(1234) * -1, _rub(-1234));
    });

    test('zero is zero in its own currency', () {
      expect(const Money.zero(Currency.rub).isZero, isTrue);
      expect(const Money.zero(Currency.rub), _rub(0));
      expect(const Money.zero(Currency.usd), isNot(_rub(0)));
    });

    test('knows its sign', () {
      expect(_rub(5).isPositive, isTrue);
      expect(_rub(-5).isNegative, isTrue);
      expect(_rub(0).isPositive || _rub(0).isNegative, isFalse);
    });
  });

  group('currencies', () {
    test('amounts of different currencies are never combined', () {
      const dollars = Money(100, Currency.usd);

      expect(
        () => _rub(100) + dollars,
        throwsA(isA<CurrencyMismatchException>()),
      );
      expect(
        () => _rub(100) - dollars,
        throwsA(isA<CurrencyMismatchException>()),
      );
      expect(
        () => _rub(100).compareTo(dollars),
        throwsA(isA<CurrencyMismatchException>()),
      );
      expect(
        () => _rub(100) < dollars,
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test('the error names the currencies and never the amounts', () {
      const error = CurrencyMismatchException(Currency.rub, Currency.usd);

      expect(
        error.toString(),
        'Cannot combine RUB and USD without a conversion',
      );
    });
  });

  group('scaled', () {
    // Made-up figures: 13 % of 120,000.00 comes out exactly.
    test('takes a percentage, exactly where it divides evenly', () {
      expect(_rub(12000000).scaled(13, 100), _rub(1560000));
    });

    // Made-up figures: 2 x 98,765.00 / 168 x 7 hours = 8,230.4166...
    test('multiplies out first and rounds once, to the minor unit', () {
      expect(_rub(9876500).scaled(2 * 7, 168), _rub(823042));
    });

    test('rounds a tie away from zero by default', () {
      expect(_rub(5).scaled(1, 2), _rub(3));
      expect(_rub(-5).scaled(1, 2), _rub(-3));
      expect(Money.defaultRounding, RoundingMode.halfAwayFromZero);
    });

    test('rounds with the mode it is given', () {
      expect(_rub(5).scaled(1, 2, rounding: RoundingMode.halfEven), _rub(2));
      expect(_rub(5).scaled(1, 2, rounding: RoundingMode.towardZero), _rub(2));
      expect(_rub(-5).scaled(1, 2, rounding: RoundingMode.floor), _rub(-3));
      expect(_rub(-5).scaled(1, 2, rounding: RoundingMode.ceiling), _rub(-2));
    });

    test('keeps the currency', () {
      expect(
        const Money(1000, Currency.usd).scaled(1, 4).currency,
        Currency.usd,
      );
    });

    test('a zero denominator is an error', () {
      expect(() => _rub(5).scaled(1, 0), throwsArgumentError);
    });
  });

  group('the range', () {
    final largest = _rub(Money.maxMinorUnits);

    test('the largest amount has fifteen digits', () {
      expect(Money.maxMinorUnits.toString(), hasLength(15));
    });

    test('going past it is an error and never a wrong amount', () {
      expect(() => largest + _rub(1), throwsRangeError);
      expect(() => -largest - _rub(1), throwsRangeError);
      expect(() => largest * 2, throwsRangeError);
      expect(() => largest.scaled(1000, 1), throwsRangeError);
      expect(
        () => Money(Money.maxMinorUnits + 1, Currency.rub),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the error does not contain the amount', () {
      expect(
        () => largest + _rub(1),
        throwsA(
          isA<RangeError>().having(
            (error) => error.toString(),
            'message',
            isNot(contains('9999')),
          ),
        ),
      );
    });

    test('shrinking back within the range works', () {
      expect(largest - largest, _rub(0));
      expect(largest.scaled(1, 1000), _rub(1000000000000));
    });
  });

  group('comparing', () {
    test('compares and sorts amounts of one currency', () {
      final sorted = [_rub(30), _rub(-5), _rub(12)]..sort();

      expect(sorted, [_rub(-5), _rub(12), _rub(30)]);
      expect(_rub(1) < _rub(2), isTrue);
      expect(_rub(2) <= _rub(2), isTrue);
      expect(_rub(3) > _rub(2), isTrue);
      expect(_rub(2) >= _rub(3), isFalse);
    });

    test('equal amounts are equal and have the same hash code', () {
      expect(_rub(7), _rub(7));
      expect(_rub(7).hashCode, _rub(7).hashCode);
      expect(_rub(7), isNot(_rub(8)));
    });
  });

  group('toDecimalString', () {
    final cases = <(Money, String)>[
      (_rub(123456), '1234.56'),
      (_rub(5), '0.05'),
      (_rub(-5), '-0.05'),
      (_rub(0), '0.00'),
      (_rub(100), '1.00'),
      (const Money(1235, Currency.jpy), '1235'),
      (const Money(-1, Currency.jpy), '-1'),
      (const Money(0, Currency.jpy), '0'),
      (const Money(1500, Currency.kwd), '1.500'),
      (const Money(-7, Currency.kwd), '-0.007'),
    ];

    for (final (money, text) in cases) {
      test(text, () => expect(money.toDecimalString(), text));
    }

    test('the debug text shows the amount and the currency', () {
      expect(_rub(1234).toString(), 'Money(12.34 RUB)');
    });
  });

  group('tryParse', () {
    Money? parse(String text, [Currency currency = Currency.rub]) {
      return Money.tryParse(text, currency);
    }

    test('reads amounts with a point or a comma', () {
      expect(parse('1234.56'), _rub(123456));
      expect(parse('1234,56'), _rub(123456));
      expect(parse('12'), _rub(1200));
      expect(parse('12.5'), _rub(1250));
    });

    test('reads a sign, spaces around the text and leading zeros', () {
      expect(parse('-0.05'), _rub(-5));
      expect(parse('+7'), _rub(700));
      expect(parse('  12.5 '), _rub(1250));
      expect(parse('007.5'), _rub(750));
      expect(parse('0'), _rub(0));
    });

    test(
      'reads Arabic-Indic and Persian digits, as typed on their keyboards',
      () {
        expect(parse('١٢٣٤٫٥٦'), _rub(123456));
        expect(parse('۱۲.۵'), _rub(1250));
      },
    );

    test('follows the fraction digits of the currency', () {
      expect(parse('1235', Currency.jpy), const Money(1235, Currency.jpy));
      expect(parse('1.500', Currency.kwd), const Money(1500, Currency.kwd));
    });

    test('rejects an amount that would need rounding', () {
      expect(parse('1.234'), isNull);
      expect(parse('12.5', Currency.jpy), isNull);
      expect(parse('1.2345', Currency.kwd), isNull);
    });

    test('rejects anything that is not a plain amount', () {
      for (final text in [
        '',
        ' ',
        'abc',
        '1.2.3',
        '.',
        '.5',
        '5.',
        '--5',
        '1,234.56',
        '1 234',
        '12 ₽',
        '1e3',
      ]) {
        expect(parse(text), isNull, reason: '"$text"');
      }
    });

    test('accepts the largest amount and rejects one digit more', () {
      expect(parse('9999999999999.99'), _rub(Money.maxMinorUnits));
      expect(parse('10000000000000.00'), isNull);
    });
  });

  group('text round trip', () {
    test(
      'reads back exactly what toDecimalString wrote, for every currency',
      () {
        final random = Random(42);
        for (final currency in Currency.values) {
          final edges = [
            0,
            1,
            -1,
            99,
            100,
            Money.maxMinorUnits,
            -Money.maxMinorUnits,
          ];
          final amounts = [
            ...edges,
            for (var i = 0; i < 300; i++)
              (random.nextInt(1 << 30) * random.nextInt(1 << 20)) %
                  (Money.maxMinorUnits + 1) *
                  (random.nextBool() ? 1 : -1),
          ];

          for (final minorUnits in amounts) {
            final money = Money(minorUnits, currency);

            expect(
              Money.tryParse(money.toDecimalString(), currency),
              money,
              reason: '$currency $minorUnits',
            );
          }
        }
      },
    );
  });
}
