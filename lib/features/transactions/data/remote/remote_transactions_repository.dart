import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/core/network/paged.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/text/api_text.dart';
import 'package:money_scribe/features/transactions/data/remote/transactions_wire.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transactions_page.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

/// The transactions on the server: the real [TransactionsRepository].
///
/// The lists are asked a page at a time with the filters of the server, and
/// the totals of the days come from their own call, paged the same way, so the
/// two can be read in step. Adding a transaction sends an `Idempotency-Key`
/// that is kept until the call has an answer, so a retry after a lost answer
/// adds nothing twice. A change and a delete send the `version` they were made
/// from (`If-Match`).
class RemoteTransactionsRepository implements TransactionsRepository {
  new({
    required this._transactions,
    required this._reports,
    required this._keys,
    required this._baseUrl,
    required this._payCycle,
  });

  /// The transactions calls over [dio], which carries the token of the session
  /// and renews it. [payCycle] says how the salary is paid and on which days,
  /// which the settings of the account hold. The keys of the adds that wait
  /// for an answer live in [keys].
  factory create({
    required Dio dio,
    required Future<PayCycle> Function() payCycle,
    IdempotencyKeys? keys,
  }) {
    return RemoteTransactionsRepository(
      transactions: api.TransactionsClient(dio),
      reports: api.ReportsClient(dio),
      keys: keys ?? IdempotencyKeys(),
      baseUrl: dio.options.baseUrl,
      payCycle: payCycle,
    );
  }

  final api.TransactionsClient _transactions;
  final api.ReportsClient _reports;
  final IdempotencyKeys _keys;
  final String _baseUrl;
  final Future<PayCycle> Function() _payCycle;

  /// The server does not push changes, and the screens load again when they
  /// come back from the form that changed something.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<TransactionsPage> transactions(
    TransactionFilter filter, {
    String? cursor,
    int pageSize = TransactionsRepository.defaultPageSize,
  }) async {
    final page = await callApi(
      () => _transactions.transactionList(
        accountId: _ids(filter.accountIds),
        categoryId: _ids(filter.categoryIds),
        cursor: cursor,
        dateFrom: filter.from,
        dateTo: filter.to,
        limit: pageSize,
        search: filter.searchTerm,
      ),
      _map,
    );
    return TransactionsPage(
      items: [
        for (final item in page.results) TransactionsWire.transaction(item),
      ],
      nextCursor: cursorOfNextPage(page.next, baseUrl: _baseUrl),
    );
  }

  @override
  Future<DayTotalsPage> dayTotals(
    TransactionFilter filter, {
    String? cursor,
    int pageSize = TransactionsRepository.defaultPageSize,
  }) async {
    final page = await callApi(
      () => _reports.reportDayTotals(
        accountId: _ids(filter.accountIds),
        categoryId: _ids(filter.categoryIds),
        cursor: cursor,
        dateFrom: filter.from,
        dateTo: filter.to,
        limit: pageSize,
      ),
      _map,
    );
    return DayTotalsPage(
      days: [for (final day in page.results) TransactionsWire.dayTotal(day)],
      nextCursor: cursorOfNextPage(page.next, baseUrl: _baseUrl),
    );
  }

  @override
  Future<Transaction?> transaction(String id) async {
    try {
      final wire = await callApi(
        () => _transactions.transactionRead(id: id),
        (failure) => failure.isNotFound ? const _Gone() : _map(failure),
      );
      return TransactionsWire.transaction(wire);
    } on _Gone {
      return null;
    }
  }

  @override
  Future<Transaction> add(TransactionDraft draft) async {
    final note = ApiText.clean(draft.note);
    // One action of the person: the same transaction.
    final action =
        'transaction:add:${draft.kind.name}:${draft.amount.toDecimalString()}:'
        '${draft.amount.currency.code}:${_dayText(draft.date)}:'
        '${draft.categoryId}:${draft.accountId}:$note:'
        '${draft.part?.month.param}:${draft.part?.part.name}';
    final (part, partMonth) = TransactionsWire.partToWire(draft.part);
    final wire = await callApi(
      () => _keys.run(
        action,
        (key) => _transactions.transactionCreate(
          idempotencyKey: WriteSafetyHeaders.idempotencyKey(key),
          body: api.TransactionCreateRequest(
            kind: TransactionsWire.transactionKindToWire(draft.kind),
            amount: draft.amount.toDecimalString(),
            currency: TransactionsWire.currencyToWire(draft.amount.currency),
            date: draft.date,
            categoryId: draft.categoryId,
            accountId: draft.accountId,
            note: note,
            partValue: part,
            partMonth: partMonth,
          ),
        ),
      ),
      _mapWrite,
    );
    return TransactionsWire.transaction(wire);
  }

  @override
  Future<Transaction> update(
    String id,
    TransactionDraft draft, {
    required int version,
  }) async {
    // Both fields, or none: an income with no chosen part joins the one
    // whose pay day is nearest to its day, as the server works it out.
    final (part, partMonth) = TransactionsWire.partToWire(draft.part);
    final wire = await callApi(
      // The currency is not sent: it cannot be changed.
      () => _transactions.transactionUpdate(
        id: id,
        ifMatch: WriteSafetyHeaders.ifMatch(version),
        body: api.PatchedTransactionUpdateRequest(
          kind: TransactionsWire.transactionKindToWire(draft.kind),
          amount: draft.amount.toDecimalString(),
          date: draft.date,
          categoryId: draft.categoryId,
          accountId: draft.accountId,
          note: ApiText.clean(draft.note),
          partValue: part,
          partMonth: partMonth,
        ),
      ),
      // A transaction that is gone was deleted on another device: the same
      // answer as one that changed there.
      (failure) => failure.isNotFound
          ? const StaleRecordException()
          : _mapWrite(failure),
    );
    return TransactionsWire.transaction(wire);
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    try {
      await callApi(
        () => _transactions.transactionDelete(
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
  Future<PayCycle> payCycle() => _payCycle();

  /// The ids to send, or none (every record) when the filter has none. The
  /// server takes at most [TransactionFilter.maxIds]; the Filters sheet keeps
  /// to it.
  static List<String>? _ids(Set<String> ids) {
    return ids.isEmpty ? null : ids.take(TransactionFilter.maxIds).toList();
  }

  static String _dayText(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  Exception _map(ApiFailure failure) => failure.toDataException();

  /// The refusals of a write that the person can act on; the rest are the
  /// failures every repository shares.
  Exception _mapWrite(ApiFailure failure) {
    if (failure.statusCode == 409 &&
        failure.hasCode('transaction_limit_reached')) {
      return const TransactionRefusedException(TransactionRefusal.limitReached);
    }
    if (failure.statusCode == 400) {
      if (failure.hasCode('category_not_allowed')) {
        return const TransactionRefusedException(
          TransactionRefusal.categoryNotAllowed,
        );
      }
      if (failure.hasCode('does_not_exist')) {
        return const TransactionRefusedException(
          TransactionRefusal.categoryOrAccountGone,
        );
      }
      if (failure.hasCode('date_out_of_range')) {
        return const TransactionRefusedException(
          TransactionRefusal.dateOutOfRange,
        );
      }
    }
    return _map(failure);
  }
}

/// The answer was `404 not_found`: there is no such transaction.
final class _Gone implements Exception {
  const new();
}
