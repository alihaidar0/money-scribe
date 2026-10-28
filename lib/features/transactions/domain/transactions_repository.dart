import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transactions_page.dart';

/// Where the transactions come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class TransactionsRepository {
  /// How many transactions (or days) a page holds unless asked otherwise.
  static const defaultPageSize = 50;

  /// Emits when the transactions may have changed without the app saving them,
  /// so a screen showing them loads them again.
  Stream<void> get changes;

  /// A page of the transactions that pass [filter], the newest first. Without
  /// a [cursor] it is the first page; with the `nextCursor` of a page it is
  /// the one after it. [pageSize] is how many a page holds.
  Future<TransactionsPage> transactions(
    TransactionFilter filter, {
    String? cursor,
    int pageSize = defaultPageSize,
  });

  /// A page of what each day came to, for the days of the transactions that
  /// pass [filter] (its search words are not used: a total of only the
  /// matching rows would mislead), the newest day first. [pageSize] counts
  /// days.
  Future<DayTotalsPage> dayTotals(
    TransactionFilter filter, {
    String? cursor,
    int pageSize = defaultPageSize,
  });

  /// The transaction [id], or `null` when there is none.
  Future<Transaction?> transaction(String id);

  /// Adds the transaction [draft] and returns it with its id. Throws
  /// [TransactionRefusedException] when the server refuses it for a reason the
  /// person can act on.
  Future<Transaction> add(TransactionDraft draft);

  /// Replaces what the transaction [id] is made of and returns it. [version]
  /// is the version the change was made from: a transaction that changed
  /// since throws a `StaleRecordException` and nothing is changed. The
  /// currency of a transaction cannot be changed.
  Future<Transaction> update(
    String id,
    TransactionDraft draft, {
    required int version,
  });

  /// Deletes the transaction [id] at [version]. A transaction that changed
  /// since throws a `StaleRecordException`. Deleting one that is gone does
  /// nothing.
  Future<void> delete(String id, {required int version});

  /// How the account's salary is paid and on which days, which decides
  /// whether the transactions are shown by part of the month, and where each
  /// part starts and ends.
  Future<PayCycle> payCycle();
}
