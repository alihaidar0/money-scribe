import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/core/network/omit_nulls_interceptor.dart';
import 'package:money_scribe/core/network/paged.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/core/text/api_text.dart';
import 'package:money_scribe/features/debts/data/remote/debts_wire.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

/// The debts on the server: the real [DebtsRepository].
///
/// The list is read whole, a page of up to 100 at a time, and handed over
/// oldest first. Adding a debt or a repayment sends an `Idempotency-Key` that
/// is kept until the call has an answer, so a retry after a lost answer adds
/// nothing twice. A change and a delete send the `version` they were made from
/// (`If-Match`): the debt's for a debt, the repayment's own for a repayment.
/// Every repayment call answers with the whole debt.
class RemoteDebtsRepository implements DebtsRepository {
  new({
    required this._debts,
    required this._clearing,
    required this._keys,
    required this._baseUrl,
    required this._defaultCurrency,
  });

  /// The debts calls over [dio], which carries the token of the session and
  /// renews it. [defaultCurrency] is the one the settings of the account hold.
  /// The keys of the adds that wait for an answer live in [keys].
  factory create({
    required Dio dio,
    required Future<Currency> Function() defaultCurrency,
    IdempotencyKeys? keys,
  }) {
    // `{"due_date": null}` is how a change takes the due day away, so the
    // change is sent by a client that keeps the `null` fields of a body.
    final clearing = dio.clone();
    clearing.interceptors.removeWhere(
      (interceptor) => interceptor is OmitNullsInterceptor,
    );
    return RemoteDebtsRepository(
      debts: api.DebtsClient(dio),
      clearing: api.DebtsClient(clearing),
      keys: keys ?? IdempotencyKeys(),
      baseUrl: dio.options.baseUrl,
      defaultCurrency: defaultCurrency,
    );
  }

  /// The server keeps at most 500 debts: five pages of 100.
  static const _pageSize = 100;
  static const _maxPages = 5;

  final api.DebtsClient _debts;
  final api.DebtsClient _clearing;
  final IdempotencyKeys _keys;
  final String _baseUrl;
  final Future<Currency> Function() _defaultCurrency;

  /// The server does not push changes, and the screens load again when they
  /// come back from the form that changed something.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<Debt>> debts() async {
    final newestFirst = await readAllPages<Debt>((cursor) async {
      final page = await callApi(
        () => _debts.debtList(cursor: cursor, limit: _pageSize),
        _map,
      );
      return Paged(
        items: [for (final item in page.results) DebtsWire.debt(item)],
        next: cursorOfNextPage(page.next, baseUrl: _baseUrl),
      );
    }, maxPages: _maxPages);
    return newestFirst.reversed.toList();
  }

  @override
  Future<Debt?> debt(String id) async {
    try {
      final wire = await callApi(
        () => _debts.debtRead(id: id),
        (failure) => failure.isNotFound ? const _Gone() : _map(failure),
      );
      return DebtsWire.debt(wire);
    } on _Gone {
      return null;
    }
  }

  @override
  Future<Debt> add(DebtDraft draft) async {
    final person = ApiText.clean(draft.person);
    final note = ApiText.clean(draft.note);
    // One action of the person: the same debt.
    final action =
        'debt:add:${draft.direction.name}:$person:'
        '${draft.amount.toDecimalString()}:${draft.amount.currency.code}:'
        '${_dayText(draft.startDate)}:${_dayText(draft.dueDate)}:$note';
    final wire = await callApi(
      () => _keys.run(
        action,
        (key) => _debts.debtCreate(
          idempotencyKey: WriteSafetyHeaders.idempotencyKey(key),
          body: api.DebtCreateRequest(
            direction: DebtsWire.directionToWire(draft.direction),
            person: person,
            amount: draft.amount.toDecimalString(),
            currency: DebtsWire.currencyToWire(draft.amount.currency),
            startDate: draft.startDate,
            dueDate: draft.dueDate,
            note: note,
          ),
        ),
      ),
      (failure) => _mapWrite(failure, draft.amount.currency),
    );
    return DebtsWire.debt(wire);
  }

  @override
  Future<Debt> update(
    String id,
    DebtDraft draft, {
    required int version,
  }) async {
    final wire = await callApi(
      // The direction and the currency are not sent: they cannot be changed.
      () => _clearing.debtUpdate(
        id: id,
        ifMatch: WriteSafetyHeaders.ifMatch(version),
        body: api.PatchedDebtUpdateRequest(
          person: ApiText.clean(draft.person),
          amount: draft.amount.toDecimalString(),
          startDate: draft.startDate,
          dueDate: draft.dueDate,
          note: ApiText.clean(draft.note),
        ),
      ),
      (failure) => _mapChange(failure, draft.amount.currency),
    );
    return DebtsWire.debt(wire);
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    try {
      await callApi(
        () => _debts.debtDelete(
          id: id,
          ifMatch: WriteSafetyHeaders.ifMatch(version),
        ),
        (failure) => failure.isNotFound ? const _Gone() : _map(failure),
      );
    } on _Gone {
      // Already gone: the person wanted it gone.
    }
  }

  @override
  Future<Debt> addRepayment(String debtId, RepaymentDraft draft) async {
    final action =
        'debt:repay:$debtId:${draft.amount.toDecimalString()}:'
        '${_dayText(draft.date)}';
    final wire = await callApi(
      () => _keys.run(
        action,
        (key) => _debts.debtRepaymentCreate(
          idempotencyKey: WriteSafetyHeaders.idempotencyKey(key),
          id: debtId,
          body: api.RepaymentInputRequest(
            amount: draft.amount.toDecimalString(),
            date: draft.date,
          ),
        ),
      ),
      // A debt that is gone was deleted on another device: the same answer as
      // one that changed there.
      (failure) => failure.isNotFound
          ? const StaleRecordException()
          : _mapWrite(failure, draft.amount.currency),
    );
    return DebtsWire.debt(wire);
  }

  @override
  Future<Debt> updateRepayment(
    String debtId,
    String repaymentId,
    RepaymentDraft draft, {
    required int version,
  }) async {
    final wire = await callApi(
      () => _debts.debtRepaymentUpdate(
        id: debtId,
        repaymentId: repaymentId,
        ifMatch: WriteSafetyHeaders.ifMatch(version),
        body: api.PatchedRepaymentInputRequest(
          amount: draft.amount.toDecimalString(),
          date: draft.date,
        ),
      ),
      (failure) => _mapChange(failure, draft.amount.currency),
    );
    return DebtsWire.debt(wire);
  }

  @override
  Future<Debt> deleteRepayment(
    String debtId,
    String repaymentId, {
    required int version,
  }) async {
    try {
      final wire = await callApi(
        () => _debts.debtRepaymentDelete(
          id: debtId,
          repaymentId: repaymentId,
          ifMatch: WriteSafetyHeaders.ifMatch(version),
        ),
        (failure) => failure.isNotFound ? const _Gone() : _map(failure),
      );
      return DebtsWire.debt(wire);
    } on _Gone {
      // The repayment is already gone: the person wanted it gone. Its debt is
      // read again, and a debt that is gone too is a change made elsewhere.
      return await debt(debtId) ?? (throw const StaleRecordException());
    }
  }

  @override
  Future<Currency> defaultCurrency() => _defaultCurrency();

  /// A calendar day as the key of an action, or nothing for no day.
  static String _dayText(DateTime? date) =>
      date == null ? '' : '${date.year}-${date.month}-${date.day}';

  Exception _map(ApiFailure failure) => failure.toDataException();

  /// The refusals of a change, where a record that is gone is the same as one
  /// that changed elsewhere.
  Exception _mapChange(ApiFailure failure, Currency currency) {
    return failure.isNotFound
        ? const StaleRecordException()
        : _mapWrite(failure, currency);
  }

  /// The refusals of a write that the person can act on; the rest are the
  /// failures every repository shares. [currency] is the one of the amount
  /// sent, which `remaining` of a refusal is in.
  Exception _mapWrite(ApiFailure failure, Currency currency) {
    if (failure.statusCode == 409) {
      if (failure.hasCode('debt_limit_reached')) {
        return const DebtRefusedException(DebtRefusal.limitReached);
      }
      if (failure.hasCode('repayment_limit_reached')) {
        return const DebtRefusedException(DebtRefusal.repaymentLimitReached);
      }
    }
    if (failure.statusCode == 400) {
      final remaining = failure.items
          .where((item) => item.code == 'exceeds_remaining')
          .firstOrNull;
      if (remaining != null) {
        final text = remaining.remaining;
        return DebtRefusedException(
          DebtRefusal.exceedsRemaining,
          remaining: text == null ? null : Money.tryParse(text, currency),
        );
      }
      const codes = {
        'amount_below_repaid': DebtRefusal.amountBelowRepaid,
        'due_before_start': DebtRefusal.dueBeforeStart,
        'repayment_before_start': DebtRefusal.repaymentBeforeStart,
        'start_after_repayment': DebtRefusal.startAfterRepayment,
        'date_out_of_range': DebtRefusal.dateOutOfRange,
      };
      for (final entry in codes.entries) {
        if (failure.hasCode(entry.key)) {
          return DebtRefusedException(entry.value);
        }
      }
    }
    return _map(failure);
  }
}

/// The answer was `404 not_found`: there is no such record.
final class _Gone implements Exception {
  const new();
}
