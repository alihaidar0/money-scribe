import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

/// The transactions of one day, the newest added first, with what they come
/// to: the income minus the expenses.
final class DayGroup extends Equatable {
  const new({
    required this.date,
    required this.transactions,
    required this.total,
  });

  final DateTime date;
  final List<Transaction> transactions;
  final Money total;

  @override
  List<Object> get props => [date, transactions, total];
}

/// The days of one part of one month, for a month paid in two payments. [part]
/// is [PeriodScope.firstPart] (the 1st-15th) or [PeriodScope.secondPart] (the
/// 16th-end).
final class PeriodGroup extends Equatable {
  const new({required this.month, required this.part, required this.days});

  final YearMonth month;
  final PeriodScope part;
  final List<DayGroup> days;

  @override
  List<Object> get props => [month, part, days];
}

/// Puts transactions in days, and the days in the parts of their month.
abstract final class TransactionGroups {
  /// The days of [transactions], the newest day first. Within a day the
  /// transaction added last comes first, as [transactions] are in the order
  /// they were added.
  static List<DayGroup> byDay(List<Transaction> transactions) {
    final days = <DateTime, List<Transaction>>{};
    for (final transaction in transactions.reversed) {
      final date = transaction.date;
      days
          .putIfAbsent(DateTime(date.year, date.month, date.day), () => [])
          .add(transaction);
    }
    final dates = days.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final date in dates)
        DayGroup(
          date: date,
          transactions: days[date]!,
          total: days[date]!.fold<Money>(
            Money.zero(days[date]!.first.amount.currency),
            (sum, transaction) => sum + transaction.signedAmount,
          ),
        ),
    ];
  }

  /// The days of [transactions] in the part of the month each belongs to, the
  /// newest part first.
  static List<PeriodGroup> byPeriod(List<Transaction> transactions) {
    final periods = <PeriodGroup>[];
    for (final day in byDay(transactions)) {
      final month = YearMonth.fromDate(day.date);
      final part = PeriodScope.partOfDay(day.date.day);
      if (periods.isNotEmpty &&
          periods.last.month == month &&
          periods.last.part == part) {
        periods.last.days.add(day);
      } else {
        periods.add(PeriodGroup(month: month, part: part, days: [day]));
      }
    }
    return periods;
  }

  /// The last day of [month]: 28 to 31.
  static int lastDayOf(YearMonth month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }
}
