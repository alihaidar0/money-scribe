import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';

/// Writes a day the way the language does, such as `5 Oct` or `Mon 5 Oct`,
/// with Western digits in every language. Always go through this class; never
/// format a date by hand.
class DayFormatter {
  new(Locale locale)
    : _languageCode = locale.languageCode,
      _day = DateFormat.d(locale.toLanguageTag()),
      _month = DateFormat.MMM(locale.toLanguageTag()),
      _weekday = DateFormat.E(locale.toLanguageTag());

  final String _languageCode;
  final DateFormat _day;
  final DateFormat _month;
  final DateFormat _weekday;

  /// The day and the short month, such as `5 Oct`.
  String format(DateTime date) {
    final number = WesternDigits.normalize(_day.format(date));
    return '$number ${_month.format(date)}';
  }

  /// [format] with the year when it is not the year of [today], such as
  /// `5 Oct 2025`.
  String formatDate(DateTime date, {required DateTime today}) {
    if (date.year == today.year) return format(date);
    return '${format(date)} ${WesternDigits.normalize('${date.year}')}';
  }

  /// The weekday, the day and the short month, such as `Mon 5 Oct`. With
  /// [today] a day in another year also has its year.
  String formatWithWeekday(DateTime date, {DateTime? today}) {
    final day = today == null ? format(date) : formatDate(date, today: today);
    return '${_weekday.format(date)} $day';
  }

  /// The day as an ordinal in English (`1st`, `22nd`, `31st`), and as the plain
  /// number in other languages.
  String ordinal(int day) {
    if (_languageCode != 'en') return WesternDigits.normalize('$day');
    final lastTwo = day % 100;
    final suffix = lastTwo >= 11 && lastTwo <= 13
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$day$suffix';
  }
}
