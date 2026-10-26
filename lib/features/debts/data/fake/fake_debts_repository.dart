import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/data/fake/debts_seed.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

/// Debts made of invented figures, until the server exists. It follows the
/// demo panel: no data, slow, failing or offline. What the app adds, changes
/// or deletes is kept in memory for as long as it runs.
///
/// It keeps the rules of the server: a change or a delete needs the version it
/// was made from (a repayment has its own, and does not change its debt's); a
/// repayment cannot be more than what is left, or dated before the debt
/// starts; the amount cannot go below what was repaid, nor the start day past
/// a repayment; and there are at most [maxDebts] debts with
/// [maxRepayments] repayments each.
class FakeDebtsRepository implements DebtsRepository {
  new({
    required this._demo,
    this.maxDebts = defaultMaxDebts,
    this.maxRepayments = defaultMaxRepayments,
    Future<Currency> Function()? defaultCurrency,
  }) : _defaultCurrency = defaultCurrency ?? (() async => Currency.rub);

  /// The most debts a person has on the server.
  static const defaultMaxDebts = 500;

  /// The most repayments a debt has on the server.
  static const defaultMaxRepayments = 200;

  /// The first and the last day the server keeps.
  static final firstDay = DateTime(2000);
  static final lastDay = DateTime(2099, 12, 31);

  final DemoController _demo;

  /// The most debts and repayments this fake holds (a test sets small ones).
  final int maxDebts;
  final int maxRepayments;

  final Future<Currency> Function() _defaultCurrency;

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
    final debts = _current();
    if (debts.length >= maxDebts) {
      throw const DebtRefusedException(DebtRefusal.limitReached);
    }
    _checkDay(draft.startDate);
    final due = draft.dueDate;
    if (due != null) _checkDay(due);
    final debt = Debt(
      id: 'added-${_nextId++}',
      direction: draft.direction,
      person: draft.person,
      amount: draft.amount,
      startDate: draft.startDate,
      dueDate: draft.dueDate,
      note: draft.note,
    );
    _edited = [...debts, debt];
    return debt;
  }

  @override
  Future<Debt> update(
    String id,
    DebtDraft draft, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final old = _versioned(id, version);
    _checkDay(draft.startDate);
    final due = draft.dueDate;
    if (due != null) _checkDay(due);
    if (draft.amount < old.repaid) {
      throw const DebtRefusedException(DebtRefusal.amountBelowRepaid);
    }
    final lastRepayment = old.lastRepaymentDate;
    if (lastRepayment != null && draft.startDate.isAfter(lastRepayment)) {
      throw const DebtRefusedException(DebtRefusal.startAfterRepayment);
    }
    // The direction and the currency are fixed, whatever the draft says.
    final debt = Debt(
      id: id,
      direction: old.direction,
      person: draft.person,
      amount: draft.amount,
      startDate: draft.startDate,
      dueDate: draft.dueDate,
      note: draft.note,
      repayments: old.repayments,
      version: old.draft == draft ? version : version + 1,
    );
    return _store(debt);
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    await _demo.simulateSave();
    final found = _find(id);
    if (found == null) return;
    if (found.version != version) throw const StaleRecordException();
    _edited = [
      for (final debt in _current())
        if (debt.id != id) debt,
    ];
  }

  @override
  Future<Debt> addRepayment(String debtId, RepaymentDraft draft) async {
    await _demo.simulateSave();
    final debt = _find(debtId) ?? (throw const StaleRecordException());
    if (debt.repayments.length >= maxRepayments) {
      throw const DebtRefusedException(DebtRefusal.repaymentLimitReached);
    }
    _checkRepayment(debt, draft, allowance: debt.remaining);
    final repayment = Repayment.fromDraft('added-${_nextId++}', draft);
    return _store(debt.withRepayments(_byDay([...debt.repayments, repayment])));
  }

  @override
  Future<Debt> updateRepayment(
    String debtId,
    String repaymentId,
    RepaymentDraft draft, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final debt = _find(debtId) ?? (throw const StaleRecordException());
    final old = _repaymentVersioned(debt, repaymentId, version);
    // The repayment's own amount counts towards what is left.
    _checkRepayment(debt, draft, allowance: debt.remaining + old.amount);
    final changed = Repayment.fromDraft(
      repaymentId,
      draft,
      version: old.draft == draft ? version : version + 1,
    );
    return _store(
      debt.withRepayments(
        _byDay([
          for (final repayment in debt.repayments)
            if (repayment.id == repaymentId) changed else repayment,
        ]),
      ),
    );
  }

  @override
  Future<Debt> deleteRepayment(
    String debtId,
    String repaymentId, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final debt = _find(debtId) ?? (throw const StaleRecordException());
    final found = debt.repayments.where((item) => item.id == repaymentId);
    // Already gone: the person wanted it gone.
    if (found.isEmpty) return debt;
    if (found.first.version != version) throw const StaleRecordException();
    return _store(
      debt.withRepayments([
        for (final repayment in debt.repayments)
          if (repayment.id != repaymentId) repayment,
      ]),
    );
  }

  @override
  Future<Currency> defaultCurrency() => _defaultCurrency();

  /// Checks a repayment against the rules of the server; [allowance] is the
  /// most it can be.
  void _checkRepayment(
    Debt debt,
    RepaymentDraft draft, {
    required Money allowance,
  }) {
    _checkDay(draft.date);
    if (draft.date.isBefore(debt.startDate)) {
      throw const DebtRefusedException(DebtRefusal.repaymentBeforeStart);
    }
    if (draft.amount > allowance) {
      throw DebtRefusedException(
        DebtRefusal.exceedsRemaining,
        remaining: allowance,
      );
    }
  }

  void _checkDay(DateTime day) {
    if (day.isBefore(firstDay) || day.isAfter(lastDay)) {
      throw const DebtRefusedException(DebtRefusal.dateOutOfRange);
    }
  }

  /// The repayments as the server lists them: by day, and in the order they
  /// were added within a day.
  List<Repayment> _byDay(List<Repayment> repayments) {
    final order = {
      for (var i = 0; i < repayments.length; i++) repayments[i].id: i,
    };
    return [...repayments]..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : order[a.id]!.compareTo(order[b.id]!);
    });
  }

  /// The debt [id] at [version]. A debt that is gone or changed is stale.
  Debt _versioned(String id, int version) {
    final debt = _find(id);
    if (debt == null || debt.version != version) {
      throw const StaleRecordException();
    }
    return debt;
  }

  Repayment _repaymentVersioned(Debt debt, String id, int version) {
    for (final repayment in debt.repayments) {
      if (repayment.id == id && repayment.version == version) return repayment;
    }
    throw const StaleRecordException();
  }

  /// Puts [debt] in place of the debt of the same id and returns it.
  Debt _store(Debt debt) {
    _edited = [
      for (final item in _current())
        if (item.id == debt.id) debt else item,
    ];
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
