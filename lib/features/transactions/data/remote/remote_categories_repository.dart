import 'dart:async';

import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/core/network/paged.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/core/text/api_text.dart';
import 'package:money_scribe/features/transactions/data/remote/transactions_wire.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// The categories on the server: the real [CategoriesRepository].
///
/// Adding a category sends an `Idempotency-Key` that is kept until the call
/// has an answer, so a retry after a lost answer adds nothing twice. A change
/// and a delete send the `version` they were made from (`If-Match`).
class RemoteCategoriesRepository implements CategoriesRepository {
  new({required this._client, required this._keys, required this._baseUrl});

  /// The categories calls over [dio], which carries the token of the session
  /// and renews it. The keys of the adds that wait for an answer live in
  /// [keys].
  factory create({required Dio dio, IdempotencyKeys? keys}) {
    return RemoteCategoriesRepository(
      client: api.CategoriesClient(dio),
      keys: keys ?? IdempotencyKeys(),
      baseUrl: dio.options.baseUrl,
    );
  }

  /// Most categories a page holds: the 7 built-in ones and at most 50 of the
  /// person's own fit in one call.
  static const _pageSize = 100;

  final api.CategoriesClient _client;
  final IdempotencyKeys _keys;
  final String _baseUrl;
  final _changes = StreamController<void>.broadcast();

  /// The server does not push changes. What this device changes is announced
  /// here, so a screen that shows the categories loads them again.
  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<TransactionCategory>> categories() async {
    final wire = await readAllPages<api.Category>((next) async {
      final page = await callApi(
        () => _client.categoryList(
          cursor: cursorOfNextPage(next, baseUrl: _baseUrl),
          limit: _pageSize,
        ),
        _map,
      );
      return Paged(items: page.results, next: page.next);
    });
    return [for (final category in wire) TransactionsWire.category(category)];
  }

  @override
  Future<TransactionCategory> add(CategoryDraft draft) async {
    final name = ApiText.clean(draft.name);
    // One action of the person: the same name and icon.
    final action = 'category:add:$name:${draft.icon.name}';
    final wire = await callApi(
      () => _keys.run(
        action,
        (key) => _client.categoryCreate(
          idempotencyKey: WriteSafetyHeaders.idempotencyKey(key),
          body: api.CategoryInputRequest(
            name: name,
            icon: TransactionsWire.iconToWire(draft.icon),
          ),
        ),
      ),
      _mapWrite,
    );
    _changes.add(null);
    return TransactionsWire.category(wire);
  }

  @override
  Future<TransactionCategory> update(
    String id,
    CategoryDraft draft, {
    required int version,
  }) async {
    final wire = await callApi(
      () => _client.categoryUpdate(
        id: id,
        ifMatch: WriteSafetyHeaders.ifMatch(version),
        body: api.PatchedCategoryInputRequest(
          name: ApiText.clean(draft.name),
          icon: TransactionsWire.iconToWire(draft.icon),
        ),
      ),
      // A category that is gone was deleted on another device: the same
      // answer as a category that changed there.
      (failure) => failure.isNotFound
          ? const StaleRecordException()
          : _mapWrite(failure),
    );
    _changes.add(null);
    return TransactionsWire.category(wire);
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    try {
      await callApi(
        () => _client.categoryDelete(
          id: id,
          ifMatch: WriteSafetyHeaders.ifMatch(version),
        ),
        (failure) => failure.isNotFound ? const _Gone() : _mapWrite(failure),
      );
    } on _Gone {
      // Already gone: the person wanted it gone.
    }
    _changes.add(null);
  }

  Exception _map(ApiFailure failure) => failure.toDataException();

  /// The refusals of a write that the person can act on; the rest are the
  /// failures every repository shares.
  Exception _mapWrite(ApiFailure failure) {
    if (failure.statusCode == 400 && failure.hasCode('name_taken')) {
      return const CategoryRefusedException(CategoryRefusal.nameTaken);
    }
    if (failure.statusCode == 409) {
      if (failure.hasCode('category_limit_reached')) {
        return const CategoryRefusedException(CategoryRefusal.limitReached);
      }
    }
    return _map(failure);
  }
}

/// The answer was `404 not_found`: there is no such category.
final class _Gone implements Exception {
  const new();
}
