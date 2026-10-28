import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

/// One page of the transactions, the newest first, and where the next page
/// is.
final class TransactionsPage extends Equatable {
  const new({required this.items, this.nextCursor});

  final List<Transaction> items;

  /// What to ask for the next page, or `null` on the last one. It is opaque:
  /// it is given back exactly as it came.
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}

/// What one day came to: the income minus the expenses, once for each currency
/// that day has transactions in, ordered by currency code.
final class DayTotal extends Equatable {
  const new({required this.date, required this.totals});

  final DateTime date;

  /// Signed: positive when the day brought in more than it took out.
  final List<Money> totals;

  @override
  List<Object> get props => [date, totals];
}

/// One page of day totals, the newest day first. Every page holds whole days.
final class DayTotalsPage extends Equatable {
  const new({required this.days, this.nextCursor});

  final List<DayTotal> days;
  final String? nextCursor;

  @override
  List<Object?> get props => [days, nextCursor];
}
