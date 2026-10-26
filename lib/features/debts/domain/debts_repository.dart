import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

/// Where the debts come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails, and the writes
/// throw a [DebtRefusedException] when the server refuses what was typed for a
/// reason the person can act on.
///
/// A change or a delete names the version it was made from: a record that
/// changed since (on another device, say) throws a `StaleRecordException` and
/// nothing is changed. A debt and each of its repayments have their own
/// version, and a repayment does not change the version of its debt.
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

  /// Replaces what the debt [id] is made of at [version], keeping its
  /// repayments, and returns it. The direction and the currency of a debt
  /// cannot be changed.
  Future<Debt> update(String id, DebtDraft draft, {required int version});

  /// Deletes the debt [id] at [version] with its repayments. Deleting one that
  /// is gone does nothing.
  Future<void> delete(String id, {required int version});

  /// Adds a repayment to the debt [debtId] and returns the debt.
  Future<Debt> addRepayment(String debtId, RepaymentDraft draft);

  /// Replaces what a repayment of the debt [debtId] is made of at the
  /// repayment's [version] and returns the debt.
  Future<Debt> updateRepayment(
    String debtId,
    String repaymentId,
    RepaymentDraft draft, {
    required int version,
  });

  /// Deletes a repayment of the debt [debtId] at the repayment's [version] and
  /// returns the debt.
  Future<Debt> deleteRepayment(
    String debtId,
    String repaymentId, {
    required int version,
  });

  /// The currency a new debt is in and the totals are shown in: the default
  /// currency of the account.
  Future<Currency> defaultCurrency();
}
