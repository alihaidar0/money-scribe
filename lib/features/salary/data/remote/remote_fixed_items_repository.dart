import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/features/salary/data/remote/salary_wire.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';

/// The fixed items of the months on the server: the real
/// [FixedItemsRepository].
///
/// Adding an item sends an `Idempotency-Key` that is kept until the call has
/// an answer, so a retry after a lost answer adds nothing twice. A change and
/// a delete send the `version` they were made from (`If-Match`).
class RemoteFixedItemsRepository implements FixedItemsRepository {
  new({required this._client, required this._keys});

  /// The fixed items calls over [dio], which carries the token of the session
  /// and renews it. The keys of the adds that wait for an answer live in
  /// [keys].
  factory create({required Dio dio, IdempotencyKeys? keys}) {
    return RemoteFixedItemsRepository(
      client: api.SalaryClient(dio),
      keys: keys ?? IdempotencyKeys(),
    );
  }

  final api.SalaryClient _client;
  final IdempotencyKeys _keys;

  /// The server does not push changes, and the app is the only writer on this
  /// device: a screen loads again when it is opened.
  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<FixedItem>> items(YearMonth month) async {
    try {
      final wire = await callApi(
        () => _client.salaryMonthRead(month: month.param),
        _mapMissing,
      );
      return [for (final item in wire.fixedItems) SalaryWire.fixedItem(item)];
    } on _Missing {
      // A month that was not saved has no items.
      return const [];
    }
  }

  @override
  Future<FixedItem> add(YearMonth month, FixedItemDraft draft) async {
    // One action of the person: the same draft for the same month.
    final action =
        'fixed-item:add:${month.param}:${draft.name}:'
        '${draft.amount.toDecimalString()}:${draft.kind.name}:'
        '${draft.part.name}';
    final wire = await callApi(
      () => _keys.run(
        action,
        (key) => _client.salaryFixedItemCreate(
          idempotencyKey: WriteSafetyHeaders.idempotencyKey(key),
          month: month.param,
          body: api.FixedItemInputRequest(
            name: draft.name,
            amount: draft.amount.toDecimalString(),
            kind: SalaryWire.kindToWire(draft.kind),
            currency: SalaryWire.currencyToWire(draft.amount.currency),
            partValue: SalaryWire.partToWire(draft.part),
          ),
        ),
      ),
      _map,
    );
    return SalaryWire.fixedItem(wire);
  }

  @override
  Future<FixedItem> update(
    YearMonth month,
    String id,
    FixedItemDraft draft, {
    required int version,
  }) async {
    final wire = await callApi(
      () => _client.salaryFixedItemUpdate(
        id: id,
        ifMatch: WriteSafetyHeaders.ifMatch(version),
        body: api.PatchedFixedItemInputRequest(
          name: draft.name,
          amount: draft.amount.toDecimalString(),
          kind: SalaryWire.kindToWire(draft.kind),
          currency: SalaryWire.currencyToWire(draft.amount.currency),
          partValue: SalaryWire.partToWire(draft.part),
        ),
      ),
      // An item that is gone was deleted on another device: the same answer
      // as an item that changed there.
      (failure) => failure.statusCode == 404
          ? const StaleRecordException()
          : _map(failure),
    );
    return SalaryWire.fixedItem(wire);
  }

  @override
  Future<void> delete(
    YearMonth month,
    String id, {
    required int version,
  }) async {
    try {
      await callApi(
        () => _client.salaryFixedItemDelete(
          id: id,
          ifMatch: WriteSafetyHeaders.ifMatch(version),
        ),
        _mapMissing,
      );
    } on _Missing {
      // Already gone: the person wanted it gone.
    }
  }

  Exception _map(ApiFailure failure) => failure.toDataException();

  Exception _mapMissing(ApiFailure failure) {
    return failure.statusCode == 404 ? const _Missing() : _map(failure);
  }
}

/// The answer was `404`: nothing is saved there.
final class _Missing implements Exception {
  const new();
}
