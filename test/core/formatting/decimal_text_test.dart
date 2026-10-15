import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/formatting/decimal_text.dart';

void main() {
  group('parseCount', () {
    test('reads a whole number', () {
      expect(DecimalText.parseCount('20'), 20);
      expect(DecimalText.parseCount('  160 '), 160);
      expect(DecimalText.parseCount('007'), 7);
    });

    test('reads digits typed on an Arabic keyboard', () {
      expect(DecimalText.parseCount('٢٠'), 20);
    });

    test('refuses anything else', () {
      expect(DecimalText.parseCount(''), isNull);
      expect(DecimalText.parseCount('-1'), isNull);
      expect(DecimalText.parseCount('1.5'), isNull);
      expect(DecimalText.parseCount('abc'), isNull);
      expect(DecimalText.parseCount('1234567890'), isNull);
    });
  });

  group('parseHundredths', () {
    test('keeps whole numbers and decimals as hundredths', () {
      expect(DecimalText.parseHundredths('13'), 1300);
      expect(DecimalText.parseHundredths('7.5'), 750);
      expect(DecimalText.parseHundredths('7.25'), 725);
      expect(DecimalText.parseHundredths('0.05'), 5);
      expect(DecimalText.parseHundredths('0'), 0);
    });

    test('accepts a comma as the point', () {
      expect(DecimalText.parseHundredths('7,5'), 750);
    });

    test('accepts a number that is still being typed', () {
      expect(DecimalText.parseHundredths('7.'), 700);
      expect(DecimalText.parseHundredths('.5'), 50);
    });

    test('reads Arabic digits and separators', () {
      expect(DecimalText.parseHundredths('٧٫٥'), 750);
    });

    test('refuses anything else', () {
      expect(DecimalText.parseHundredths(''), isNull);
      expect(DecimalText.parseHundredths('.'), isNull);
      expect(DecimalText.parseHundredths('7.255'), isNull);
      expect(DecimalText.parseHundredths('1.2.3'), isNull);
      expect(DecimalText.parseHundredths('-1'), isNull);
      expect(DecimalText.parseHundredths('abc'), isNull);
      expect(DecimalText.parseHundredths('1234567890'), isNull);
    });
  });

  group('formatHundredths', () {
    test('drops needless zeros', () {
      expect(DecimalText.formatHundredths(1300), '13');
      expect(DecimalText.formatHundredths(750), '7.5');
      expect(DecimalText.formatHundredths(1305), '13.05');
      expect(DecimalText.formatHundredths(10), '0.1');
      expect(DecimalText.formatHundredths(5), '0.05');
      expect(DecimalText.formatHundredths(0), '0');
    });

    test('reads back what it writes', () {
      for (final value in [0, 1, 5, 10, 99, 100, 750, 1305, 1350, 10000]) {
        expect(
          DecimalText.parseHundredths(DecimalText.formatHundredths(value)),
          value,
        );
      }
    });
  });
}
