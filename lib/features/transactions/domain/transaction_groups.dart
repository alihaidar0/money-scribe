import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

/// The transactions of one day, the newest added first, with what the whole
/// day came to: the income minus the expenses, once for each currency.
final class DayGroup extends Equatable {
  const new({required this.date, required this.transactions, this.totals});

  final DateTime date;
  final List<Transaction> transactions;

  /// What the day came to, which the server counts, or `null` when it is not
  /// known (a search is on, so the totals of the whole day would mislead, or
  /// the totals of this day are not loaded yet).
  final List<Money>? totals;

  @override
  List<Object?> get props => [date, transactions, totals];
}

/// The days of one part of one month, for a month paid in two payments. [part]
/// is [PeriodScope.firstPart] or [PeriodScope.secondPart]; [range] is the days
/// the part covers, cut at the pay days.
final class PeriodGroup extends Equatable {
  const new({
    required this.month,
    required this.part,
    required this.range,
    required this.days,
  });

  final YearMonth month;
  final PeriodScope part;
  final PayPeriod range;
  final List<DayGroup> days;

  @override
  List<Object> get props => [month, part, range, days];
}

/// Puts transactions in days, and the days in the parts of their month.
abstract final class TransactionGroups {
  /// The days of [transactions], the newest day first. [transactions] are in
  /// the order the server sends them: the newest day first and, within a day,
  /// the one added last first. [totals] are what each day came to (see
  /// [DayGroup.totals]); a day missing from it has none.
  static List<DayGroup> byDay(
    List<Transaction> transactions, {
    Map<DateTime, List<Money>>? totals,
  }) {
    final days = <DateTime, List<Transaction>>{};
    for (final transaction in transactions) {
      final date = transaction.date;
      days
          .putIfAbsent(DateTime(date.year, date.month, date.day), () => [])
          .add(transaction);
    }
    final dates = days.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final date in dates)
        DayGroup(date: date, transactions: days[date]!, totals: totals?[date]),
    ];
  }

  /// The days of [transactions] in the part of the month each belongs to by
  /// the pay days of [cycle], the newest part first.
  static List<PeriodGroup> byPeriod(
    List<Transaction> transactions, {
    required PayCycle cycle,
    Map<DateTime, List<Money>>? totals,
  }) {
    final periods = <PeriodGroup>[];
    for (final day in byDay(transactions, totals: totals)) {
      final month = cycle.monthOf(day.date);
      final part = cycle.partOf(day.date);
      if (periods.isNotEmpty &&
          periods.last.month == month &&
          periods.last.part == part) {
        periods.last.days.add(day);
      } else {
        periods.add(
          PeriodGroup(
            month: month,
            part: part,
            range: cycle.rangeOf(month, part),
            days: [day],
          ),
        );
      }
    }
    return periods;
  }
}
