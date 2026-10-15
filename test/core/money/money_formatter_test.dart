import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter.dart';

void main() {
  const leftToRightIsolate = '\u2066';
  const popDirectionalIsolate = '\u2069';
  const noBreakSpace = '\u00a0';

  group('format', () {
    test('in English puts the symbol after the number, kopecks included', () {
      final formatter = MoneyFormatter(const Locale('en'));

      expect(
        formatter.format(const Money(6065000, Currency.rub)),
        '60,650.00$noBreakSpace₽',
      );
      expect(
        formatter.format(const Money(123456, Currency.rub)),
        '1,234.56$noBreakSpace₽',
      );
      expect(
        formatter.format(const Money(-50, Currency.usd)),
        '-0.50$noBreakSpace\$',
      );
      expect(
        formatter.format(const Money(1235, Currency.jpy)),
        '1,235$noBreakSpace¥',
      );
    });

    test('in Arabic keeps the same look, isolated from the Arabic text', () {
      final formatter = MoneyFormatter(const Locale('ar'));

      expect(
        formatter.format(const Money(123456, Currency.rub)),
        '${leftToRightIsolate}1,234.56$noBreakSpace₽$popDirectionalIsolate',
      );
    });

    test('a negative amount in Arabic keeps its minus before the digits', () {
      final shown = MoneyFormatter(const Locale('ar'))
          .format(const Money(-50, Currency.usd));

      expect(shown, startsWith(leftToRightIsolate));
      expect(shown, endsWith(popDirectionalIsolate));
      expect(shown, contains('-0.50$noBreakSpace\$'));
    });

    test('adds no control characters outside right-to-left languages', () {
      for (final locale in const [Locale('en'), Locale('ru'), Locale('de')]) {
        final shown = MoneyFormatter(locale)
            .format(const Money(123456, Currency.rub));

        expect(shown, isNot(contains(leftToRightIsolate)), reason: '$locale');
        expect(
          shown,
          isNot(contains(popDirectionalIsolate)),
          reason: '$locale',
        );
      }
    });

    test('in Russian follows the Russian separators', () {
      final formatter = MoneyFormatter(const Locale('ru'));

      expect(
        formatter.format(const Money(123456, Currency.rub)),
        '1${noBreakSpace}234,56$noBreakSpace₽',
      );
    });

    test('shows the code of a currency without a common symbol', () {
      final formatter = MoneyFormatter(const Locale('en'));

      expect(
        formatter.format(const Money(1234500, Currency.sar)),
        contains('SAR'),
      );
      expect(
        formatter.format(const Money(1234500, Currency.sar)),
        contains('12,345.00'),
      );
    });

    test('uses the fraction digits of the currency', () {
      final formatter = MoneyFormatter(const Locale('en'));

      expect(formatter.formatAmount(const Money(1500, Currency.kwd)), '1.500');
      expect(formatter.formatAmount(const Money(1500, Currency.jpy)), '1,500');
      expect(formatter.formatAmount(const Money(1500, Currency.rub)), '15.00');
    });
  });

  group('formatSigned', () {
    test('puts a plus before income and a true minus before expenses', () {
      final formatter = MoneyFormatter(const Locale('en'));

      expect(
        formatter.formatSigned(const Money(10440000, Currency.rub)),
        '+104,400.00$noBreakSpace₽',
      );
      expect(
        formatter.formatSigned(const Money(-5275000, Currency.rub)),
        '\u2212'
        '52,750.00$noBreakSpace₽',
      );
    });

    test('zero has a plus', () {
      expect(
        MoneyFormatter(const Locale('en'))
            .formatSigned(const Money(0, Currency.rub)),
        '+0.00$noBreakSpace₽',
      );
    });

    test('never uses a hyphen', () {
      final text = MoneyFormatter(const Locale('en'))
          .formatSigned(const Money(-100, Currency.rub));

      expect(text, isNot(contains('-')));
    });

    test('in Arabic the sign stays with the digits inside the isolates', () {
      final text = MoneyFormatter(const Locale('ar'))
          .formatSigned(const Money(-5275000, Currency.rub));

      expect(text.runes.first, 0x2066);
      expect(text.runes.last, 0x2069);
      expect(text.substring(1, 2), '\u2212');
      expect(text, contains('52,750.00'));
    });
  });

  group('formatAmount', () {
    test('shows the number without the currency', () {
      expect(
        MoneyFormatter(const Locale('en'))
            .formatAmount(const Money(123456, Currency.rub)),
        '1,234.56',
      );
    });

    test('keeps the sign and a leading zero', () {
      final formatter = MoneyFormatter(const Locale('en'));

      expect(formatter.formatAmount(const Money(-5, Currency.rub)), '-0.05');
      expect(formatter.formatAmount(const Money(0, Currency.rub)), '0.00');
    });
  });

  group('the symbol is after the number in every language', () {
    for (final locale in const [
      Locale('en'),
      Locale('ar'),
      Locale('ar', 'EG'),
      Locale('fa'),
      Locale('ru'),
      Locale('de'),
    ]) {
      test('$locale', () {
        final formatter = MoneyFormatter(locale);

        for (final currency in Currency.values) {
          final shown = formatter
              .format(Money(123456, currency))
              .replaceAll(leftToRightIsolate, '')
              .replaceAll(popDirectionalIsolate, '');

          expect(
            shown,
            endsWith('$noBreakSpace${currency.displaySymbol}'),
            reason: '$locale $currency "$shown"',
          );
        }
      });
    }
  });

  test('shows every fraction digit of the currency, kopecks included', () {
    final formatter = MoneyFormatter(const Locale('en'));

    expect(
      formatter.format(const Money(100000, Currency.rub)),
      '1,000.00$noBreakSpace₽',
    );
    expect(
      formatter.format(const Money(5, Currency.rub)),
      '0.05$noBreakSpace₽',
    );
    expect(
      formatter.format(const Money(1500, Currency.kwd)),
      '1.500${noBreakSpace}KWD',
    );
  });

  group('Western digits in every language', () {
    const locales = [
      Locale('en'),
      Locale('ar'),
      Locale('ar', 'EG'),
      Locale('ar', 'SA'),
      Locale('ar', 'SY'),
      Locale('fa'),
      Locale('ru'),
      Locale('de'),
    ];
    final amounts = [
      0,
      5,
      -5,
      123456,
      -9876543210,
      Money.maxMinorUnits,
      -Money.maxMinorUnits,
    ];

    for (final locale in locales) {
      test('$locale, for every currency and amount', () {
        final formatter = MoneyFormatter(locale);

        for (final currency in Currency.values) {
          for (final minorUnits in amounts) {
            final money = Money(minorUnits, currency);
            final shown = formatter.format(money);
            final amountOnly = formatter.formatAmount(money);

            expect(
              WesternDigits.hasNonWesternDigits(shown),
              isFalse,
              reason: shown,
            );
            // Every digit is there; none is lost to rounding, even at the max.
            expect(
              amountOnly.replaceAll(RegExp(r'\D'), ''),
              money.toDecimalString().replaceAll(RegExp(r'\D'), ''),
              reason: '$locale $currency $minorUnits shown as "$amountOnly"',
            );
          }
        }
      });
    }
  });
}
