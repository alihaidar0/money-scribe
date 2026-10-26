/// The text rules of the server for every text a person types: no control
/// character (a line break and a tab included), none of the bidirectional
/// override, embedding and isolate characters, and no unpaired surrogate. The
/// server rejects such a value with `400 invalid_characters`.
///
/// The app wraps amounts in exactly those isolates in Arabic, so a copied
/// amount carries them into a text field: they are removed here, before the
/// text is sent, and never shown to the person as an error. The direction
/// marks (U+200E, U+200F, U+061C) and the joiners (U+200C, U+200D) stay,
/// because Arabic text needs them.
///
/// Passwords are never cleaned: they are sent exactly as typed. Imported CSV
/// cells are not cleaned either: the server reports the row.
abstract final class ApiText {
  /// [value] without the characters the server refuses. A line break, a tab
  /// and the separators U+0085, U+2028 and U+2029 become a space, so words
  /// that were on two lines stay two words; every other character that is
  /// refused is removed. Trimming and normalising are left to the server.
  static String clean(String value) {
    if (!_needsCleaning(value)) return value;
    final units = value.codeUnits;
    final result = StringBuffer();
    for (var index = 0; index < units.length; index++) {
      final unit = units[index];
      if (_isHighSurrogate(unit)) {
        final hasPair =
            index + 1 < units.length && _isLowSurrogate(units[index + 1]);
        if (hasPair) {
          result
            ..writeCharCode(unit)
            ..writeCharCode(units[++index]);
        }
        continue;
      }
      if (_isLowSurrogate(unit)) continue;
      if (_becomesSpace(unit)) {
        result.write(' ');
      } else if (!_isRefused(unit)) {
        result.writeCharCode(unit);
      }
    }
    return result.toString();
  }

  static bool _needsCleaning(String value) {
    for (final unit in value.codeUnits) {
      if (unit < 0x20 ||
          (unit >= 0x7F && unit <= 0x9F) ||
          (unit >= 0x2028 && unit <= 0x202E) ||
          (unit >= 0x2066 && unit <= 0x2069) ||
          (unit >= 0xD800 && unit <= 0xDFFF)) {
        return true;
      }
    }
    return false;
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;

  static bool _isLowSurrogate(int unit) => unit >= 0xDC00 && unit <= 0xDFFF;

  static bool _becomesSpace(int unit) =>
      unit == 0x09 ||
      unit == 0x0A ||
      unit == 0x0B ||
      unit == 0x0C ||
      unit == 0x0D ||
      unit == 0x85 ||
      unit == 0x2028 ||
      unit == 0x2029;

  static bool _isRefused(int unit) =>
      unit < 0x20 ||
      (unit >= 0x7F && unit <= 0x9F) ||
      (unit >= 0x202A && unit <= 0x202E) ||
      (unit >= 0x2066 && unit <= 0x2069);
}
