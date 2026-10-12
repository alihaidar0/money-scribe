import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/debts/data/fake/debts_seed.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

/// Debts made of invented figures, until the server exists. It follows the
/// demo panel: no data, slow, failing or offline. What the app adds, changes
/// or deletes is kept in memory for as long as it runs.
class FakeDebtsRepository implements DebtsRepository {
  new({required this._demo});

  final DemoController _demo;

  /// What the app changed since it started; it replaces the seed.
  List<Debt>? _edited;

  var _nextId = 1;

  @override
  Stream<void> get changes => _demo.dataChanges;

  @override
  Future<List<Debt>> debts() async {
    await _demo.simulateRequest();
    return List.unmodifiable(_current());
  }

  @override
  Future<Debt?> debt(String id) async {
    await _demo.simulateRequest();
    return _find(id);
  }

  @override
  Future<Debt> add(DebtDraft draft) async {
    await _demo.simulateSave();
    final debt = Debt(
      id: 'added-${_nextId++}',
      direction: draft.direction,
      person: draft.person,
      amount: draft.amount,
      startDate: draft.startDate,
      dueDate: draft.dueDate,
      note: draft.note,
    );
    _edited = [..._current(), debt];
    return debt;
  }

  @override
  Future<Debt> update(String id, DebtDraft draft) async {
    await _demo.simulateSave();
    return _replace(id, (debt) => debt.withDraft(draft));
  }

  @override
  Future<void> delete(String id) async {
    await _demo.simulateSave();
    _edited = [
      for (final debt in _current())
        if (debt.id != id) debt,
    ];
  }

  @override
  Future<Debt> addRepayment(String debtId, RepaymentDraft draft) async {
    await _demo.simulateSave();
    final repayment = Repayment.fromDraft('added-${_nextId++}', draft);
    return _replace(
      debtId,
      (debt) => debt.withRepayments([...debt.repayments, repayment]),
    );
  }

  @override
  Future<Debt> updateRepayment(
    String debtId,
    String repaymentId,
    RepaymentDraft draft,
  ) async {
    await _demo.simulateSave();
    return _replace(
      debtId,
      (debt) => debt.withRepayments([
        for (final repayment in debt.repayments)
          if (repayment.id == repaymentId)
            Repayment.fromDraft(repaymentId, draft)
          else
            repayment,
      ]),
    );
  }

  @override
  Future<Debt> deleteRepayment(String debtId, String repaymentId) async {
    await _demo.simulateSave();
    return _replace(
      debtId,
      (debt) => debt.withRepayments([
        for (final repayment in debt.repayments)
          if (repayment.id != repaymentId) repayment,
      ]),
    );
  }

  /// Replaces the debt [id] with what [change] makes of it, and returns it. A
  /// debt that is gone is a server failure.
  Debt _replace(String id, Debt Function(Debt debt) change) {
    final debts = _current();
    final index = debts.indexWhere((debt) => debt.id == id);
    if (index < 0) throw const ServerException();

    final debt = change(debts[index]);
    _edited = [...debts]..[index] = debt;
    return debt;
  }

  Debt? _find(String id) {
    for (final debt in _current()) {
      if (debt.id == id) return debt;
    }
    return null;
  }

  /// The debts, without waiting for the server.
  List<Debt> _current() {
    final edited = _edited;
    if (edited != null) return edited;
    if (_demo.settings.scenario == DemoScenario.empty) return const [];
    return DebtsSeed.debts();
  }
}
