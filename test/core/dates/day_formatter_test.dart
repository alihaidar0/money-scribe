import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_scribe/core/dates/day_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });

  const english = Locale('en');
  const arabic = Locale('ar');
  final october5 = DateTime(2026, 10, 5);

  group('format', () {
    test('writes the day and the short month', () {
      expect(DayFormatter(english).format(october5), '5 Oct');
    });

    test('uses Western digits in Arabic', () {
      final text = DayFormatter(arabic).format(october5);

      expect(text, contains('5'));
      expect(text, isNot(matches('[٠-٩]')));
    });
  });

  group('formatDate', () {
    test('leaves the year out for the year of today', () {
      expect(
        DayFormatter(english).formatDate(october5, today: DateTime(2026, 11)),
        '5 Oct',
      );
    });

    test('adds the year for another year', () {
      expect(
        DayFormatter(english).formatDate(october5, today: DateTime(2027, 1, 3)),
        '5 Oct 2026',
      );
    });
  });

  group('formatWithWeekday', () {
    test('puts the weekday first', () {
      expect(DayFormatter(english).formatWithWeekday(october5), 'Mon 5 Oct');
    });

    test('adds the year for another year when told today', () {
      expect(
        DayFormatter(english)
            .formatWithWeekday(october5, today: DateTime(2027, 1, 3)),
        'Mon 5 Oct 2026',
      );
    });
  });

  group('ordinal', () {
    test('adds the English suffix', () {
      final days = DayFormatter(english);

      expect(
        [
          for (final day in [1, 2, 3, 4, 11, 12, 13, 15, 16, 21, 22, 23, 31])
            days.ordinal(day),
        ],
        [
          '1st',
          '2nd',
          '3rd',
          '4th',
          '11th',
          '12th',
          '13th',
          '15th',
          '16th',
          '21st',
          '22nd',
          '23rd',
          '31st',
        ],
      );
    });

    test('is the plain number in other languages', () {
      expect(DayFormatter(arabic).ordinal(16), '16');
    });
  });

  group('formatWithYear', () {
    test('always has the year', () {
      expect(DayFormatter(english).formatWithYear(october5), '5 Oct 2026');
    });

    test('uses Western digits in Arabic', () {
      expect(
        DayFormatter(arabic).formatWithYear(october5),
        isNot(matches('[٠-٩]')),
      );
    });
  });

  group('formatTime', () {
    test('is on a 24-hour clock', () {
      expect(
        DayFormatter(english).formatTime(DateTime(2026, 10, 5, 18, 40)),
        '18:40',
      );
      expect(
        DayFormatter(english).formatTime(DateTime(2026, 10, 5, 9, 5)),
        '09:05',
      );
    });

    test('uses Western digits in Arabic', () {
      expect(
        DayFormatter(arabic).formatTime(DateTime(2026, 10, 5, 18, 40)),
        '18:40',
      );
    });
  });

  group('isSameDay', () {
    test('compares the calendar day, not the time', () {
      final formatter = DayFormatter(english);

      expect(
        formatter.isSameDay(
          DateTime(2026, 10, 5, 1),
          DateTime(2026, 10, 5, 23),
        ),
        isTrue,
      );
      expect(
        formatter.isSameDay(DateTime(2026, 10, 5), DateTime(2025, 10, 5)),
        isFalse,
      );
    });
  });
}
