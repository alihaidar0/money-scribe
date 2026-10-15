import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/formatting/decimal_input_formatter.dart';

TextEditingValue _value(String text) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

String _type(
  DecimalInputFormatter formatter, {
  required String before,
  required String after,
}) {
  return formatter.formatEditUpdate(_value(before), _value(after)).text;
}

void main() {
  group('whole numbers', () {
    const formatter = DecimalInputFormatter();

    test('lets digits through', () {
      expect(_type(formatter, before: '2', after: '20'), '20');
      expect(_type(formatter, before: '20', after: ''), '');
    });

    test('refuses a point, a sign and letters', () {
      expect(_type(formatter, before: '20', after: '20.'), '20');
      expect(_type(formatter, before: '20', after: '-20'), '20');
      expect(_type(formatter, before: '20', after: '20a'), '20');
    });

    test('turns Arabic digits into Western ones', () {
      expect(_type(formatter, before: '', after: '٢٠'), '20');
    });
  });

  group('with decimals', () {
    const formatter = DecimalInputFormatter(maxFractionDigits: 2);

    test('lets one point or comma and two decimals through', () {
      expect(_type(formatter, before: '12', after: '12.'), '12.');
      expect(_type(formatter, before: '12.5', after: '12.50'), '12.50');
      expect(_type(formatter, before: '12', after: '12,5'), '12,5');
    });

    test('refuses a third decimal and a second point', () {
      expect(_type(formatter, before: '12.50', after: '12.505'), '12.50');
      expect(_type(formatter, before: '12.5', after: '12.5.'), '12.5');
    });

    test('turns the Arabic point into a Western one', () {
      expect(_type(formatter, before: '٧', after: '٧٫٥'), '7.5');
    });

    test('refuses a pasted number with grouping', () {
      expect(_type(formatter, before: '', after: '1,234.50'), '');
    });
  });

  test('limits the whole digits', () {
    const formatter = DecimalInputFormatter(maxWholeDigits: 3);

    expect(_type(formatter, before: '123', after: '1234'), '123');
  });
}
