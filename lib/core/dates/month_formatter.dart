import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';

/// Writes a month the way the language does, such as `October 2026`, with
/// Western digits in every language. Always go through this class; never
/// format a date by hand.
class MonthFormatter {
  new(Locale locale) : _format = DateFormat.yMMMM(locale.toLanguageTag());

  final DateFormat _format;

  String format(YearMonth month) {
    return WesternDigits.normalize(_format.format(month.firstDay));
  }
}
