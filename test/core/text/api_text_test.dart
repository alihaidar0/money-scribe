import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/text/api_text.dart';
import 'package:money_scribe/core/text/api_text_formatter.dart';

void main() {
  group('ApiText.clean', () {
    test('leaves ordinary text alone, Arabic and emoji included', () {
      const text = 'Café متجر الأحمد 🛒 – 12.50';

      expect(ApiText.clean(text), text);
    });

    test('keeps the direction marks and the joiners Arabic needs', () {
      const text = 'a‎b‏c؜d‌e‍f';

      expect(ApiText.clean(text), text);
    });

    test('a line break, a tab and the separators become a space', () {
      expect(
        ApiText.clean('a\nb\r\nc\td\u2028e\u2029f\u0085g'),
        'a b  c d e f g',
      );
    });

    test('removes the other control characters', () {
      expect(ApiText.clean('a\u0000b\u0007c\u007Fd\u009Fe'), 'abcde');
    });

    test('removes the direction overrides, embeddings and isolates', () {
      expect(
        ApiText.clean(
          '\u202ASam\u202B\u202C\u202D\u202EEvil\u2066x\u2067y\u2068z\u2069',
        ),
        'SamEvilxyz',
      );
    });

    test('removes an unpaired surrogate but keeps a pair', () {
      expect(ApiText.clean('a\uD800b\uDC00c'), 'abc');
      expect(ApiText.clean('a😀b'), 'a😀b');
    });

    test('an amount copied from Arabic text loses only its isolates', () {
      expect(ApiText.clean('\u206660,650.00 ₽\u2069'), '60,650.00 ₽');
    });
  });

  group('ApiTextFormatter', () {
    const formatter = ApiTextFormatter();

    TextEditingValue pasted(String text, {int? caret}) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    );

    test('does not touch text that is already clean', () {
      final value = pasted('Rent');

      expect(formatter.formatEditUpdate(TextEditingValue.empty, value), value);
    });

    test('cleans a paste and keeps the cursor after what was pasted', () {
      final result = formatter.formatEditUpdate(
        pasted('Rent'),
        pasted('Rent\u202E and\nbills', caret: 'Rent\u202E and\n'.length),
      );

      expect(result.text, 'Rent and bills');
      expect(result.selection.baseOffset, 'Rent and '.length);
      expect(result.selection.isCollapsed, isTrue);
    });

    test('keeps a selection inside the cleaned text', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'a\u202Eb\u202Ec',
          selection: TextSelection(baseOffset: 2, extentOffset: 5),
        ),
      );

      expect(result.text, 'abc');
      expect(
        result.selection,
        const TextSelection(baseOffset: 1, extentOffset: 3),
      );
    });
  });
}
