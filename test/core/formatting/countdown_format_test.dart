import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/formatting/bidi_isolate.dart';
import 'package:money_scribe/core/formatting/countdown_format.dart';
import 'package:money_scribe/core/formatting/western_digits_input_formatter.dart';

void main() {
  group('formatCountdown', () {
    test('shows minutes and two-digit seconds', () {
      expect(formatCountdown(299), '4:59');
      expect(formatCountdown(300), '5:00');
      expect(formatCountdown(42), '0:42');
      expect(formatCountdown(5), '0:05');
      expect(formatCountdown(0), '0:00');
    });

    test('never shows a negative time', () {
      expect(formatCountdown(-3), '0:00');
    });
  });

  test('isolateLeftToRight wraps the text in left-to-right isolates', () {
    final isolated = isolateLeftToRight('a@b.c');

    expect(isolated.runes.first, 0x2066);
    expect(isolated.runes.last, 0x2069);
    expect(isolated.substring(1, isolated.length - 1), 'a@b.c');
  });

  group('WesternDigitsInputFormatter', () {
    String format(String text) {
      return const WesternDigitsInputFormatter()
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: text),
          )
          .text;
    }

    test('keeps Western digits', () => expect(format('4817'), '4817'));

    test('turns Arabic-Indic digits into Western ones', () {
      expect(format('٤٨١٧'), '4817');
    });

    test('drops everything that is not a digit', () {
      expect(format('4 8-a1'), '481');
    });
  });
}
