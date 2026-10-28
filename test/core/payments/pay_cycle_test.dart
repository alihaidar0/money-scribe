import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/period_scope.dart';

void main() {
  final twice = PayCycle.twoPayments(firstPayDay: 20, secondPayDay: 5);
  const once = PayCycle.onePayment();
  const october = YearMonth(2026, 10);

  PayPeriod range(PayCycle cycle, YearMonth month, PeriodScope scope) =>
      cycle.rangeOf(month, scope);

  group('isValidPair', () {
    test('the second pay day is before the first', () {
      expect(PayCycle.isValidPair(firstPayDay: 20, secondPayDay: 5), isTrue);
      expect(PayCycle.isValidPair(firstPayDay: 2, secondPayDay: 1), isTrue);
    });

    test('equal or reversed pay days are not valid', () {
      expect(PayCycle.isValidPair(firstPayDay: 10, secondPayDay: 10), isFalse);
      expect(PayCycle.isValidPair(firstPayDay: 5, secondPayDay: 20), isFalse);
    });
  });

  group('partOfDay', () {
    test('the first pay day starts the first part', () {
      expect(twice.partOfDay(20), PeriodScope.firstPart);
      expect(twice.partOfDay(28), PeriodScope.firstPart);
      expect(twice.partOfDay(31), PeriodScope.firstPart);
    });

    test('the days before the second pay day are still the first part', () {
      expect(twice.partOfDay(1), PeriodScope.firstPart);
      expect(twice.partOfDay(4), PeriodScope.firstPart);
    });

    test('the second pay day starts the second part', () {
      expect(twice.partOfDay(5), PeriodScope.secondPart);
      expect(twice.partOfDay(13), PeriodScope.secondPart);
      expect(twice.partOfDay(19), PeriodScope.secondPart);
    });

    test('follows other pay days', () {
      final cycle = PayCycle.twoPayments(firstPayDay: 25, secondPayDay: 10);

      expect(cycle.partOfDay(9), PeriodScope.firstPart);
      expect(cycle.partOfDay(10), PeriodScope.secondPart);
      expect(cycle.partOfDay(24), PeriodScope.secondPart);
      expect(cycle.partOfDay(25), PeriodScope.firstPart);
    });

    test('a month paid once has no parts', () {
      expect(once.hasParts, isFalse);
      expect(once.partOfDay(3), PeriodScope.month);
      expect(once.partOfDay(25), PeriodScope.month);
    });

    test('a pair that is not in order falls back to 20 and 5', () {
      final cycle = PayCycle.twoPayments(firstPayDay: 5, secondPayDay: 20);

      expect(cycle, twice);
    });
  });

  group('partOf and monthOf', () {
    test('a date from the first pay day is the first part of its month', () {
      final date = DateTime(2026, 10, 20, 23, 59);

      expect(twice.partOf(date), PeriodScope.firstPart);
      expect(twice.monthOf(date), october);
    });

    test(
      'a date before the second pay day is the first part of the month before',
      () {
        final date = DateTime(2026, 11, 4);

        expect(twice.partOf(date), PeriodScope.firstPart);
        expect(twice.monthOf(date), october);
      },
    );

    test(
      'a date between the pay days is the second part of the month before',
      () {
        final date = DateTime(2026, 11, 13);

        expect(twice.partOf(date), PeriodScope.secondPart);
        expect(twice.monthOf(date), october);
      },
    );

    test('goes back over the turn of the year', () {
      final date = DateTime(2027, 1, 3);

      expect(twice.monthOf(date), const YearMonth(2026, 12));
    });

    test('a month paid once is the calendar month', () {
      expect(once.monthOf(DateTime(2026, 11, 3)), const YearMonth(2026, 11));
    });
  });

  group('rangeOf', () {
    test('the first part runs to the day before the second pay day', () {
      final period = range(twice, october, PeriodScope.firstPart);

      expect(period.start, DateTime(2026, 10, 20));
      expect(period.end, DateTime(2026, 11, 4));
    });

    test('the second part runs to the day before the first pay day', () {
      final period = range(twice, october, PeriodScope.secondPart);

      expect(period.start, DateTime(2026, 11, 5));
      expect(period.end, DateTime(2026, 11, 19));
    });

    test('the month is both parts', () {
      final period = range(twice, october, PeriodScope.month);

      expect(period.start, DateTime(2026, 10, 20));
      expect(period.end, DateTime(2026, 11, 19));
    });

    test(
      'the part before the second pay day on the 1st ends the month before',
      () {
        final cycle = PayCycle.twoPayments(firstPayDay: 20, secondPayDay: 1);

        expect(
          range(cycle, october, PeriodScope.firstPart).end,
          DateTime(2026, 10, 31),
        );
        expect(
          range(cycle, october, PeriodScope.secondPart).start,
          DateTime(2026, 11),
        );
      },
    );

    test('crosses the turn of the year', () {
      final period = range(twice, const YearMonth(2026, 12), PeriodScope.month);

      expect(period.start, DateTime(2026, 12, 20));
      expect(period.end, DateTime(2027, 1, 19));
    });

    test('the two parts follow each other without a gap or an overlap', () {
      final first = range(twice, october, PeriodScope.firstPart);
      final second = range(twice, october, PeriodScope.secondPart);

      expect(second.start, first.end.add(const Duration(days: 1)));
    });

    test('a month paid once is the calendar month, for every scope', () {
      for (final scope in PeriodScope.values) {
        final period = range(once, october, scope);

        expect(period.start, DateTime(2026, 10), reason: scope.name);
        expect(period.end, DateTime(2026, 10, 31), reason: scope.name);
      }
    });

    test('a day of a range is in the part that partOf reports', () {
      for (var day = 0; day < 60; day++) {
        final date = DateTime(2026, 10, 20 + day);
        final part = twice.partOf(date);
        final month = twice.monthOf(date);

        expect(
          range(twice, month, part).contains(date),
          isTrue,
          reason: '$date',
        );
      }
    });
  });

  group('PayPeriod.contains', () {
    final period = PayPeriod(
      start: DateTime(2026, 10, 20),
      end: DateTime(2026, 11, 4),
    );

    test('includes both ends, whatever the time of day', () {
      expect(period.contains(DateTime(2026, 10, 20)), isTrue);
      expect(period.contains(DateTime(2026, 11, 4, 23, 59)), isTrue);
    });

    test('excludes the days around it', () {
      expect(period.contains(DateTime(2026, 10, 19, 23, 59)), isFalse);
      expect(period.contains(DateTime(2026, 11, 5)), isFalse);
    });
  });
}
