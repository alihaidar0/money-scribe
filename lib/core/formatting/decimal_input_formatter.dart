import 'package:flutter/services.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';

/// Lets only a number through while it is typed: digits, and when
/// [maxFractionDigits] is above zero one `.` or `,` with that many digits after
/// it. Digits typed on an Arabic keyboard become Western ones, so the field
/// always shows 0-9. Anything else, a pasted letter or a second point, is
/// refused and the field keeps what it had.
class DecimalInputFormatter extends TextInputFormatter {
  const new({this.maxFractionDigits = 0, this.maxWholeDigits = 12});

  final int maxFractionDigits;
  final int maxWholeDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = WesternDigits.normalize(newValue.text);
    if (!_allows(text)) return oldValue;
    // Normalising swaps characters one for one, so the cursor stays put.
    return newValue.copyWith(text: text);
  }

  bool _allows(String text) {
    final fraction = maxFractionDigits == 0
        ? ''
        : '(?:[.,]\\d{0,$maxFractionDigits})?';
    return RegExp('^\\d{0,$maxWholeDigits}$fraction\$').hasMatch(text);
  }
}
