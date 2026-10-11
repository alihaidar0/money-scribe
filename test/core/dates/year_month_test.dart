import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_scribe/core/dates/month_formatter.dart';
import 'package:money_scribe/core/dates/year_month.dart';

void main() {
  group('YearMonth', () {
    test('steps to the next and previous month', () {
      expect(const YearMonth(2026, 10).next, const YearMonth(2026, 11));
      expect(const YearMonth(2026, 10).previous, const YearMonth(2026, 9));
    });

    test('steps over the end of the year', () {
      expect(const YearMonth(2026, 12).next, const YearMonth(2027, 1));
      expect(const YearMonth(2026, 1).previous, const YearMonth(2025, 12));
    });

    test('is the month of a date', () {
      expect(
        YearMonth.fromDate(DateTime(2026, 10, 31, 23)),
        const YearMonth(2026, 10),
      );
    });

    test('compares by year, then month', () {
      expect(const YearMonth(2026, 9) < const YearMonth(2026, 10), isTrue);
      expect(const YearMonth(2025, 12) < const YearMonth(2026, 1), isTrue);
      expect(const YearMonth(2026, 10) > const YearMonth(2026, 9), isTrue);
      expect(const YearMonth(2026, 10) >= const YearMonth(2026, 10), isTrue);
      expect(const YearMonth(2026, 10) <= const YearMonth(2026, 10), isTrue);
    });

    test('is equal to the same month', () {
      expect(const YearMonth(2026, 10), const YearMonth(2026, 10));
      expect(const YearMonth(2026, 10), isNot(const YearMonth(2025, 10)));
    });

    test('starts on the first day', () {
      expect(const YearMonth(2026, 10).firstDay, DateTime(2026, 10));
    });
  });

  group('MonthFormatter', () {
    setUpAll(initializeDateFormatting);

    test('writes the month and year in English', () {
      expect(
        MonthFormatter(const Locale('en')).format(const YearMonth(2026, 10)),
        'October 2026',
      );
    });

    test('writes the month in Arabic with Western digits', () {
      final text = MonthFormatter(const Locale('ar'))
          .format(const YearMonth(2026, 10));

      expect(text, contains('2026'));
      expect(text, isNot(matches('[٠-٩]')));
      expect(text, isNot(contains('October')));
    });
  });
}
