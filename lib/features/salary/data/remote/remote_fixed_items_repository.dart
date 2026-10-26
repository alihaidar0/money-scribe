import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/core/text/api_text.dart';
import 'package:money_scribe/features/salary/data/remote/salary_wire.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_copy_refusal.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';

/// The fixed items of the months on the server: the real
/// [FixedItemsRepository].
///
/// Adding an item and copying the items of another month send an
/// `Idempotency-Key` that is kept until the call has an answer, so a retry
/// after a lost answer adds nothing twice. A change and a delete send the
/// `version` they were made from (`If-Match`).
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
            name: ApiText.clean(draft.name),
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
          name: ApiText.clean(draft.name),
          amount: draft.amount.toDecimalString(),
          kind: SalaryWire.kindToWire(draft.kind),
          currency: SalaryWire.currencyToWire(draft.amount.currency),
          partValue: SalaryWire.partToWire(draft.part),
        ),
      ),
      // An item that is gone was deleted on another device: the same answer
      // as an item that changed there.
      (failure) =>
          failure.isNotFound ? const StaleRecordException() : _map(failure),
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

  @override
  Future<List<FixedItem>> copyFromPrevious(YearMonth month) async {
    // One action of the person: copying into this month. Without `from` the
    // server copies from the most recent saved month before it.
    final wire = await callApi(
      () => _keys.run(
        'fixed-items:copy:${month.param}',
        (key) => _client.salaryFixedItemsCopy(
          idempotencyKey: WriteSafetyHeaders.idempotencyKey(key),
          month: month.param,
          body: const api.CopyFixedItemsRequest(),
        ),
      ),
      _mapCopy,
    );
    return [for (final item in wire.fixedItems) SalaryWire.fixedItem(item)];
  }

  Exception _map(ApiFailure failure) => failure.toDataException();

  /// The refusals of a copy that the person can act on; the rest are the
  /// failures every repository shares.
  Exception _mapCopy(ApiFailure failure) {
    final refusal = switch (failure.statusCode) {
      // This month, or the one to copy from, is not saved.
      404 when failure.isNotFound => FixedItemsCopyRefusal.noEarlierMonth,
      409 when failure.hasCode('fixed_item_limit_reached') =>
        FixedItemsCopyRefusal.limitReached,
      400 when failure.hasCode('currency_mismatch') =>
        FixedItemsCopyRefusal.currencyMismatch,
      _ => null,
    };
    return refusal == null
        ? _map(failure)
        : FixedItemsCopyRefusedException(refusal);
  }

  Exception _mapMissing(ApiFailure failure) {
    return failure.isNotFound ? const _Missing() : _map(failure);
  }
}

/// The answer was `404 not_found`: nothing is saved there.
final class _Missing implements Exception {
  const new();
}
