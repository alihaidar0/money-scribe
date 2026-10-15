import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';

/// Formats [Money] for display. The look is the same in every language: the
/// number with all the fraction digits of its currency (kopecks for the ruble),
/// a no-break space, then the currency symbol, such as `1,234.50 ₽`. Only the
/// grouping and decimal separators follow the locale, and the digits are always
/// Western (0-9). Always go through this class; never format an amount by hand.
///
/// In a right-to-left language the text is wrapped in left-to-right isolates,
/// so inside an Arabic paragraph the amount keeps its order (the symbol stays
/// after the number) and a minus sign stays in front of the digits.
class MoneyFormatter {
  new(Locale locale)
    : _localeName = locale.toLanguageTag(),
      _isolate = Bidi.isRtlLanguage(locale.languageCode);

  static const _leftToRightIsolate = '\u2066';
  static const _popDirectionalIsolate = '\u2069';
  static const _noBreakSpace = '\u00a0';
  static const _plusSign = '+';
  static const _minusSign = '\u2212';

  final String _localeName;
  final bool _isolate;
  final _currencyFormats = <Currency, NumberFormat>{};
  final _amountFormats = <Currency, NumberFormat>{};

  /// The amount with its currency, such as `1,234.50 ₽`.
  String format(Money money) {
    return _render(_currencyFormat(money.currency), money);
  }

  /// The amount with its currency and an explicit sign: `+1,234.50 ₽`, or
  /// `−1,234.50 ₽` with a true minus sign (U+2212, never a hyphen). Zero has a
  /// plus. For income and expenses, where the sign is part of the meaning.
  String formatSigned(Money money) {
    final sign = money.isNegative ? _minusSign : _plusSign;
    return _render(_currencyFormat(money.currency), money.abs(), prefix: sign);
  }

  NumberFormat _currencyFormat(Currency currency) {
    final digits = currency.fractionDigits;
    return _currencyFormats[currency] ??= NumberFormat.currency(
      locale: _localeName,
      symbol: currency.displaySymbol,
      decimalDigits: digits,
      customPattern: '${_numberPattern(digits)}$_noBreakSpace¤',
    );
  }

  /// The amount alone, such as `1,234.50`, for places where the currency is
  /// already shown, such as a column header.
  String formatAmount(Money money) {
    final format = _amountFormats[money.currency] ??=
        NumberFormat.decimalPatternDigits(
          locale: _localeName,
          decimalDigits: money.currency.fractionDigits,
        );
    return _render(format, money);
  }

  String _render(NumberFormat format, Money money, {String prefix = ''}) {
    // Fifteen digits at most (Money.maxMinorUnits), so the double is exact to
    // the last digit that is shown.
    final major = money.minorUnits / _scale(money.currency);
    final text = prefix + WesternDigits.normalize(format.format(major));
    if (!_isolate) return text;
    return '$_leftToRightIsolate$text$_popDirectionalIsolate';
  }

  /// `#,##0.00` for two fraction digits, `#,##0` for none, `#,##0.000` for
  /// three.
  static String _numberPattern(int fractionDigits) {
    final fraction = fractionDigits == 0 ? '' : '.${'0' * fractionDigits}';
    return '#,##0$fraction';
  }

  static int _scale(Currency currency) {
    var scale = 1;
    for (var i = 0; i < currency.fractionDigits; i++) {
      scale *= 10;
    }
    return scale;
  }
}
