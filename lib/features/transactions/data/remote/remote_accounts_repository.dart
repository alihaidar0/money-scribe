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
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';

/// The accounts on the server: the real [AccountsRepository].
///
/// Adding an account sends an `Idempotency-Key` that is kept until the call
/// has an answer, so a retry after a lost answer adds nothing twice. A change
/// and a delete send the `version` they were made from (`If-Match`).
class RemoteAccountsRepository implements AccountsRepository {
  new({required this._client, required this._keys, required this._baseUrl});

  /// The accounts calls over [dio], which carries the token of the session and
  /// renews it. The keys of the adds that wait for an answer live in [keys].
  factory create({required Dio dio, IdempotencyKeys? keys}) {
    return RemoteAccountsRepository(
      client: api.AccountsClient(dio),
      keys: keys ?? IdempotencyKeys(),
      baseUrl: dio.options.baseUrl,
    );
  }

  /// Most accounts a page holds: a person has at most 20, so one call.
  static const _pageSize = 100;

  final api.AccountsClient _client;
  final IdempotencyKeys _keys;
  final String _baseUrl;
  final _changes = StreamController<void>.broadcast();

  /// The server does not push changes. What this device changes is announced
  /// here, so a screen that shows the accounts loads them again.
  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Account>> accounts() async {
    final wire = await readAllPages<api.Account>((next) async {
      final page = await callApi(
        () => _client.accountList(
          cursor: cursorOfNextPage(next, baseUrl: _baseUrl),
          limit: _pageSize,
        ),
        _map,
      );
      return Paged(items: page.results, next: page.next);
    });
    return [for (final account in wire) TransactionsWire.account(account)];
  }

  @override
  Future<Account> add(AccountDraft draft) async {
    final name = ApiText.clean(draft.name);
    // One action of the person: the same name and kind.
    final action = 'account:add:$name:${draft.kind.name}';
    final wire = await callApi(
      () => _keys.run(
        action,
        (key) => _client.accountCreate(
          idempotencyKey: WriteSafetyHeaders.idempotencyKey(key),
          body: api.AccountInputRequest(
            name: name,
            kind: TransactionsWire.accountKindToWire(draft.kind),
          ),
        ),
      ),
      _mapWrite,
    );
    _changes.add(null);
    return TransactionsWire.account(wire);
  }

  @override
  Future<Account> update(
    String id,
    AccountDraft draft, {
    required int version,
  }) async {
    final wire = await callApi(
      () => _client.accountUpdate(
        id: id,
        ifMatch: WriteSafetyHeaders.ifMatch(version),
        body: api.PatchedAccountInputRequest(
          name: ApiText.clean(draft.name),
          kind: TransactionsWire.accountKindToWire(draft.kind),
        ),
      ),
      // An account that is gone was deleted on another device: the same
      // answer as an account that changed there.
      (failure) => failure.isNotFound
          ? const StaleRecordException()
          : _mapWrite(failure),
    );
    _changes.add(null);
    return TransactionsWire.account(wire);
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    try {
      await callApi(
        () => _client.accountDelete(
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
      return const AccountRefusedException(AccountRefusal.nameTaken);
    }
    if (failure.statusCode == 409) {
      if (failure.hasCode('account_limit_reached')) {
        return const AccountRefusedException(AccountRefusal.limitReached);
      }
      if (failure.hasCode('account_has_transactions')) {
        return const AccountInUseException();
      }
    }
    return _map(failure);
  }
}

/// The answer was `404 not_found`: there is no such account.
final class _Gone implements Exception {
  const new();
}
