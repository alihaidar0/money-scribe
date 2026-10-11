import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';

void main() {
  group('normalize', () {
    test('turns Arabic-Indic digits into Western digits', () {
      expect(WesternDigits.normalize('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('turns Persian digits into Western digits', () {
      expect(WesternDigits.normalize('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('turns the Arabic separators into a point and a comma', () {
      expect(WesternDigits.normalize('١٬٢٣٤٫٥٠'), '1,234.50');
    });

    test('leaves Western digits, letters and symbols alone', () {
      expect(
        WesternDigits.normalize('1,234.50 ₽ ر.س abc'),
        '1,234.50 ₽ ر.س abc',
      );
    });

    test('handles an empty text', () {
      expect(WesternDigits.normalize(''), '');
    });
  });

  group('hasNonWesternDigits', () {
    test('finds Arabic-Indic and Persian digits', () {
      expect(WesternDigits.hasNonWesternDigits('total ٣'), isTrue);
      expect(WesternDigits.hasNonWesternDigits('total ۳'), isTrue);
    });

    test('is false for Western digits and for text without digits', () {
      expect(WesternDigits.hasNonWesternDigits('total 3 ₽'), isFalse);
      expect(WesternDigits.hasNonWesternDigits('المجموع'), isFalse);
    });
  });
}
