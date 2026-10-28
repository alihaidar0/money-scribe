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

  @override
  List<Object?> get props => [_days];
}
