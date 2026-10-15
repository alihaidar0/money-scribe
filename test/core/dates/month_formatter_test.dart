import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_scribe/core/dates/month_formatter.dart';
import 'package:money_scribe/core/dates/year_month.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  const october = YearMonth(2026, 10);

  group('in English', () {
    MonthFormatter formatter() => MonthFormatter(const Locale('en'));

    test('writes a month with its year', () {
      expect(formatter().format(october), 'October 2026');
    });

    test('writes a day with its month, day first', () {
      expect(formatter().formatDay(october, 20), '20 Oct');
      expect(formatter().formatDay(october.next, 5), '5 Nov');
    });

    test('names the months of the year', () {
      expect(formatter().shortName(1), 'Jan');
      expect(formatter().fullName(10), 'October');
    });
  });

  group('in Arabic', () {
    MonthFormatter formatter() => MonthFormatter(const Locale('ar'));

    test('keeps Western digits', () {
      expect(formatter().format(october), contains('2026'));
      expect(formatter().formatDay(october, 20), startsWith('20 '));
    });

    test('names the months in Arabic', () {
      expect(formatter().fullName(10), 'أكتوبر');
    });
  });
}
