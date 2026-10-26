import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

/// The fake debts that fail every write with [failure] while it is set, the way
/// the server does when it refuses what was typed (a [DebtRefusedException]) or
/// when another device changed the debt first (a `StaleRecordException`).
class RefusingDebtsRepository extends FakeDebtsRepository {
  new({required super.demo, this.failure, super.defaultCurrency});

  /// What every write throws, or `null` to behave like the plain fake.
  Exception? failure;

  void _failIfSet() {
    final error = failure;
    if (error != null) throw error;
  }

  @override
  Future<Debt> add(DebtDraft draft) async {
    _failIfSet();
    final result = await super.add(draft);
    return result;
  }

  @override
  Future<Debt> update(
    String id,
    DebtDraft draft, {
    required int version,
  }) async {
    _failIfSet();
    final result = await super.update(id, draft, version: version);
    return result;
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    _failIfSet();
    await super.delete(id, version: version);
  }

  @override
  Future<Debt> addRepayment(String debtId, RepaymentDraft draft) async {
    _failIfSet();
    final result = await super.addRepayment(debtId, draft);
    return result;
  }

  @override
  Future<Debt> updateRepayment(
    String debtId,
    String repaymentId,
    RepaymentDraft draft, {
    required int version,
  }) async {
    _failIfSet();
    final result = await super.updateRepayment(
      debtId,
      repaymentId,
      draft,
      version: version,
    );
    return result;
  }

  @override
  Future<Debt> deleteRepayment(
    String debtId,
    String repaymentId, {
    required int version,
  }) async {
    _failIfSet();
    final result = await super.deleteRepayment(
      debtId,
      repaymentId,
      version: version,
    );
    return result;
  }
}
