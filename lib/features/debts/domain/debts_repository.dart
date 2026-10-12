import 'package:money_scribe/features/debts/domain/debt.dart';

/// Where the debts come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class DebtsRepository {
  /// Emits when the debts may have changed without the app saving them, so a
  /// screen showing them loads them again.
  Stream<void> get changes;

  /// Every debt, in the order they were added.
  Future<List<Debt>> debts();

  /// The debt [id], or `null` when there is none.
  Future<Debt?> debt(String id);

  /// Adds the debt [draft] and returns it with its id.
  Future<Debt> add(DebtDraft draft);

  /// Replaces what the debt [id] is made of, keeping its repayments, and
  /// returns it.
  Future<Debt> update(String id, DebtDraft draft);

  /// Deletes the debt [id] with its repayments. Deleting one that is gone
  /// does nothing.
  Future<void> delete(String id);

  /// Adds a repayment to the debt [debtId] and returns the debt.
  Future<Debt> addRepayment(String debtId, RepaymentDraft draft);

  /// Replaces what a repayment of the debt [debtId] is made of and returns
  /// the debt.
  Future<Debt> updateRepayment(
    String debtId,
    String repaymentId,
    RepaymentDraft draft,
  );

  /// Deletes a repayment of the debt [debtId] and returns the debt.
  Future<Debt> deleteRepayment(String debtId, String repaymentId);
}
