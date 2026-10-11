import 'package:flutter/services.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';

/// Keeps only digits in a text field, as Western digits: digits typed on an
/// Arabic keyboard are turned into 0-9 and everything else is dropped.
class WesternDigitsInputFormatter extends TextInputFormatter {
  const new();

  static final _notADigit = RegExp('[^0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = WesternDigits.normalize(newValue.text)
        .replaceAll(_notADigit, '');
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
