import 'package:money_scribe/core/formatting/western_digits.dart';

/// Reads and writes the plain numbers a person types into a form: whole
/// numbers, and numbers with up to two decimals kept as hundredths (7.5 is
/// 750), so nothing is ever held in a `double`. Digits may be Western or typed
/// on an Arabic keyboard, and `.` or `,` may separate the decimals.
abstract final class DecimalText {
  /// The most digits a number may have, so the calculations stay far from
  /// overflowing.
  static const maxDigits = 9;

  static final RegExp _count = RegExp(r'^\d{1,9}$');
  static final RegExp _hundredths = RegExp(r'^(\d*)(?:[.,](\d{0,2}))?$');

  /// A whole number such as `20`, or `null` for anything else (empty text, a
  /// sign, a decimal point, too many digits).
  static int? parseCount(String text) {
    final normalized = WesternDigits.normalize(text.trim());
    return _count.hasMatch(normalized) ? int.parse(normalized) : null;
  }

  /// A number with at most two decimals, in hundredths: `7.5` and `7,5` are
  /// 750, `13` is 1300. `null` for anything else.
  static int? parseHundredths(String text) {
    final match = _hundredths.firstMatch(WesternDigits.normalize(text.trim()));
    if (match == null) return null;
    final whole = match.group(1) ?? '';
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    if (whole.isEmpty && (match.group(2) ?? '').isEmpty) return null;
    if (whole.length > maxDigits) return null;
    return int.parse('${whole.isEmpty ? '0' : whole}$fraction');
  }

  /// [hundredths] as text without needless zeros: 1300 is `13`, 750 is `7.5`,
  /// 1305 is `13.05`. The point is always `.`; it goes into a text field, which
  /// reads it back with [parseHundredths].
  static String formatHundredths(int hundredths) {
    final whole = hundredths ~/ 100;
    final fraction = (hundredths % 100).toString().padLeft(2, '0');
    final trimmed = fraction.endsWith('0') ? fraction[0] : fraction;
    return fraction == '00' ? '$whole' : '$whole.$trimmed';
  }
}
