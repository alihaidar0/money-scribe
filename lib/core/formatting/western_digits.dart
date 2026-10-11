/// Digits are always Western (0-9) in every language of the app. This turns the
/// Arabic-Indic digits (٠-٩), the Persian ones (۰-۹) and the Arabic decimal and
/// thousands separators (٫ ٬) into their Western forms, so formatted numbers
/// stay Western whatever the locale data says, and digits typed on an Arabic
/// keyboard are understood.
abstract final class WesternDigits {
  static const _arabicIndicZero = 0x0660;
  static const _persianZero = 0x06F0;
  static const _arabicDecimalSeparator = 0x066B;
  static const _arabicThousandsSeparator = 0x066C;

  /// [text] with every non-Western digit and Arabic separator replaced.
  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      buffer.writeCharCode(_normalizeRune(rune));
    }
    return buffer.toString();
  }

  /// Whether [text] contains a digit that is not a Western one.
  static bool hasNonWesternDigits(String text) {
    return text.runes.any(
      (rune) =>
          _digitValue(rune, _arabicIndicZero) != null ||
          _digitValue(rune, _persianZero) != null,
    );
  }

  static int _normalizeRune(int rune) {
    final digit =
        _digitValue(rune, _arabicIndicZero) ?? _digitValue(rune, _persianZero);
    if (digit != null) return 0x30 + digit;
    return switch (rune) {
      _arabicDecimalSeparator => 0x2E, // .
      _arabicThousandsSeparator => 0x2C, // ,
      _ => rune,
    };
  }

  static int? _digitValue(int rune, int zero) {
    final value = rune - zero;
    return value >= 0 && value <= 9 ? value : null;
  }
}
