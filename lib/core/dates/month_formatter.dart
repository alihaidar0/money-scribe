import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';

/// Writes a month the way the language does, such as `October 2026`, with
/// Western digits in every language. Always go through this class; never
/// format a date by hand.
class MonthFormatter {
  new(Locale locale)
    : _format = DateFormat.yMMMM(locale.toLanguageTag()),
      _day = DateFormat.d(locale.toLanguageTag()),
      _shortMonth = DateFormat.MMM(locale.toLanguageTag()),
      _fullMonth = DateFormat.MMMM(locale.toLanguageTag());

  final DateFormat _format;
  final DateFormat _day;
  final DateFormat _shortMonth;
  final DateFormat _fullMonth;

  /// A month with its year, such as `October 2026`.
  String format(YearMonth month) {
    return WesternDigits.normalize(_format.format(month.firstDay));
  }

  /// A day of a month, day first, such as `20 Oct`.
  String formatDay(YearMonth month, int day) {
    final date = DateTime(month.year, month.month, day);
    final number = WesternDigits.normalize(_day.format(date));
    return '$number ${_shortMonth.format(date)}';
  }

  /// The short name of a month of the year (1 to 12), such as `Oct`.
  String shortName(int month) => _shortMonth.format(DateTime(2000, month));

  /// The full name of a month of the year (1 to 12), such as `October`.
  String fullName(int month) => _fullMonth.format(DateTime(2000, month));
}
