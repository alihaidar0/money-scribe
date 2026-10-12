import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

/// Where the transactions come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class TransactionsRepository {
  /// Emits when the transactions may have changed without the app saving them,
  /// so a screen showing them loads them again.
  Stream<void> get changes;

  /// Every transaction, in the order they were added.
  Future<List<Transaction>> transactions();

  /// The transaction [id], or `null` when there is none.
  Future<Transaction?> transaction(String id);

  /// Adds the transaction [draft] and returns it with its id.
  Future<Transaction> add(TransactionDraft draft);

  /// Replaces what the transaction [id] is made of and returns it.
  Future<Transaction> update(String id, TransactionDraft draft);

  /// Deletes the transaction [id]. Deleting one that is gone does nothing.
  Future<void> delete(String id);

  /// How the account's salary is paid, which decides whether the transactions
  /// are shown by part of the month.
  Future<PaymentMode> paymentMode();
}
