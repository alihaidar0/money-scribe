import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/payments/period_scope.dart';

/// A run of calendar days, both ends included, such as 20 October to 4
/// November.
final class PayPeriod extends Equatable {
  const new({required this.start, required this.end});

  /// The first day, at midnight.
  final DateTime start;

  /// The last day, at midnight.
  final DateTime end;

  /// Whether [date] falls on one of the days, whatever the time of day.
  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  List<Object> get props => [start, end];
}

/// One part of one month paid in two payments, such as the second part of
/// October. [part] is [PeriodScope.firstPart] or [PeriodScope.secondPart].
final class PayPart extends Equatable {
  const new(this.month, this.part)
    : assert(part != PeriodScope.month, 'A part is the first or the second');

  final YearMonth month;
  final PeriodScope part;

  @override
  List<Object> get props => [month, part];
}

/// How a month is cut by the pay days: the one rule that tells which part a
/// date belongs to and which days a part covers. It follows the server, which
/// cuts the same way on every read.
///
/// A month paid twice has its first payment on the first pay day and its
/// second on the second pay day of the **next** month, and the second pay day
/// is before the first. Money is spent from the payment received most
/// recently, so for the month of October with the pay days 20 and 5:
///
/// - the first part runs from 20 October to 4 November;
/// - the second part from 5 November to 19 November;
/// - the month is both, 20 October to 19 November.
///
/// A month paid once is the calendar month, and has no parts.
final class PayCycle extends Equatable {
  /// A month paid once: the calendar month.
  const new onePayment() : _days = null;

  /// A month paid twice. A pair where the second pay day is not before the
  /// first cannot be told apart from a cycle that never ends, so it falls
  /// back to the defaults, as the server does.
  factory twoPayments({required int firstPayDay, required int secondPayDay}) {
    return isValidPair(firstPayDay: firstPayDay, secondPayDay: secondPayDay)
        ? PayCycle._((first: firstPayDay, second: secondPayDay))
        : const PayCycle._((
            first: defaultFirstPayDay,
            second: defaultSecondPayDay,
          ));
  }

  const new _(this._days);

  /// The pay days the app starts with.
  static const defaultFirstPayDay = 20;
  static const defaultSecondPayDay = 5;

  /// Whether the second pay day is before the first, the one rule a pair of
  /// pay days has.
  static bool isValidPair({
    required int firstPayDay,
    required int secondPayDay,
  }) {
    return secondPayDay < firstPayDay;
  }

  /// The pay days, or `null` for a month paid once.
  final ({int first, int second})? _days;

  /// Whether a month has two parts.
  bool get hasParts => _days != null;

  /// The part a day of the month belongs to, going by the payment received
  /// most recently: [PeriodScope.firstPart] from the first pay day, then
  /// [PeriodScope.secondPart] from the second, and the first again until the
  /// second pay day of the next month. [PeriodScope.month] for a month paid
  /// once.
  PeriodScope partOfDay(int dayOfMonth) {
    final days = _days;
    if (days == null) return PeriodScope.month;
    return dayOfMonth >= days.second && dayOfMonth < days.first
        ? PeriodScope.secondPart
        : PeriodScope.firstPart;
  }

  /// The part [date] belongs to.
  PeriodScope partOf(DateTime date) => partOfDay(date.day);

  /// The month whose part [date] belongs to: the days before the first pay day
  /// still belong to the month before.
  YearMonth monthOf(DateTime date) {
    final days = _days;
    final month = YearMonth.fromDate(date);
    if (days == null || date.day >= days.first) return month;
    return month.previous;
  }

  /// The days that [scope] of [month] covers. A month paid once is the
  /// calendar month for every scope.
  PayPeriod rangeOf(YearMonth month, PeriodScope scope) {
    final days = _days;
    if (days == null) {
      return PayPeriod(
        start: month.firstDay,
        end: DateTime(month.year, month.month + 1, 0),
      );
    }
    final next = month.next;
    // Day 0 of a month is the day before its first.
    DateTime dayBefore(YearMonth of, int day) =>
        DateTime(of.year, of.month, day - 1);
    final firstStart = DateTime(month.year, month.month, days.first);
    final secondStart = DateTime(next.year, next.month, days.second);
    return switch (scope) {
      PeriodScope.firstPart => PayPeriod(
        start: firstStart,
        end: dayBefore(next, days.second),
      ),
      PeriodScope.secondPart => PayPeriod(
        start: secondStart,
        end: dayBefore(next, days.first),
      ),
      PeriodScope.month => PayPeriod(
        start: firstStart,
        end: dayBefore(next, days.first),
      ),
    };
  }

  /// The part [date] belongs to, or `null` for a month paid once.
  PayPart? partOfDate(DateTime date) {
    if (!hasParts) return null;
    return PayPart(monthOf(date), partOf(date));
  }

  /// The days [part] covers.
  PayPeriod rangeOfPart(PayPart part) => rangeOf(part.month, part.part);

  /// The day [part] is paid: the first pay day of its month for the first
  /// part, the second pay day of the next month for the second. A month paid
  /// once has no parts, so the day is the first of the month.
  DateTime payDayOf(PayPart part) {
    final days = _days;
    if (days == null) return part.month.firstDay;
    if (part.part == PeriodScope.firstPart) {
      return DateTime(part.month.year, part.month.month, days.first);
    }
    final next = part.month.next;
    return DateTime(next.year, next.month, days.second);
  }

  /// The two payments around [date]: the last one paid on or before it, then
  /// the next one. Empty for a month paid once.
  List<PayPart> payEventsAround(DateTime date) {
    if (!hasParts) return const [];
    final day = _utcDay(date);
    final month = YearMonth.fromDate(date);
    final events = <PayPart>[
      for (final m in [month.previous, month, month.next])
        for (final part in [PeriodScope.firstPart, PeriodScope.secondPart])
          PayPart(m, part),
    ]..sort((a, b) => payDayOf(a).compareTo(payDayOf(b)));
    final next = events.indexWhere((e) => _utcDay(payDayOf(e)).isAfter(day));
    return [events[next - 1], events[next]];
  }

  /// The payment whose pay day is nearest to [date], either side of it, the
  /// later one when both are as far: the part an income joins when none is
  /// chosen. `null` for a month paid once.
  PayPart? nearestPayEvent(DateTime date) {
    final around = payEventsAround(date);
    if (around.isEmpty) return null;
    final day = _utcDay(date);
    final before = day.difference(_utcDay(payDayOf(around[0]))).inDays;
    final after = _utcDay(payDayOf(around[1])).difference(day).inDays;
    return before < after ? around[0] : around[1];
  }

  /// [date] as a calendar day in UTC, so a difference of days is not moved by
  /// a change of the clock.
  static DateTime _utcDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  @override
  List<Object?> get props => [_days];
}
