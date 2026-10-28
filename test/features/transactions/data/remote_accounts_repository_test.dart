import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/features/transactions/data/remote/remote_accounts_repository.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';

import '../../../support/fake_http_adapter.dart';
import 'transactions_json.dart';

const _id = '0198f2a4-7c3e-7b1d-9a52-3e6f1d0c4b21';
const _draft = AccountDraft(name: 'Travel card', kind: AccountKind.card);

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;
  late int keyCount;

  RemoteAccountsRepository build() {
    return RemoteAccountsRepository.create(
      dio: transactionsTestDio(server),
      keys: IdempotencyKeys(newKey: () => 'key-${++keyCount}-aaaaaaaaaaaa'),
    );
  }

  RequestOptions lastRequest() => server.requests.last;

  setUp(() {
    keyCount = 0;
    answer = (_) => jsonBody(200, accountJson());
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('accounts', () {
    test(
      'reads the whole list in one call, with the version of each',
      () async {
        answer = (_) => jsonBody(
          200,
          pageJson([
            accountJson(name: 'Card', version: 2),
            accountJson(id: 'cash', name: 'Cash', kind: 'cash'),
          ]),
        );

        final accounts = await build().accounts();

        expect(lastRequest().path, '/api/v1/accounts/');
        expect(lastRequest().queryParameters['limit'], 100);
        expect(accounts, [
          const Account(
            id: _id,
            name: 'Card',
            kind: AccountKind.card,
            version: 2,
          ),
          const Account(id: 'cash', name: 'Cash', kind: AccountKind.cash),
        ]);
      },
    );

    test('a person who deleted every account has an empty list', () async {
      answer = (_) => jsonBody(200, pageJson([]));

      expect(await build().accounts(), isEmpty);
    });

    test('a kind the app does not know is shown as Other', () async {
      answer = (_) => jsonBody(200, pageJson([accountJson(kind: 'savings')]));

      expect((await build().accounts()).single.kind, AccountKind.other);
    });

    test('reads every page and never follows another server', () async {
      answer = (options) {
        if (options.queryParameters['cursor'] == null) {
          return jsonBody(
            200,
            pageJson([
              accountJson(),
            ], next: 'https://api.example.test/api/v1/accounts/?cursor=abc'),
          );
        }
        return jsonBody(200, pageJson([accountJson(id: 'second', name: 'B')]));
      };

      expect(await build().accounts(), hasLength(2));
      expect(server.requests.last.queryParameters['cursor'], 'abc');

      server.requests.clear();
      answer = (_) => jsonBody(
        200,
        pageJson([
          accountJson(),
        ], next: 'https://evil.example.test/api/v1/accounts/?cursor=abc'),
      );
      await expectLater(build().accounts(), throwsA(isA<ServerException>()));
      expect(server.requests, hasLength(1));
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().accounts(), throwsA(isA<NoConnectionException>()));
    });
  });

  group('add', () {
    test('sends the name and kind with an Idempotency-Key', () async {
      answer = (_) => jsonBody(201, accountJson());

      final account = await build().add(_draft);

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/api/v1/accounts/');
      expect(lastRequest().data, {'name': 'Travel card', 'kind': 'card'});
      expect(lastRequest().headers['Idempotency-Key'], '"key-1-aaaaaaaaaaaa"');
      expect(account.id, _id);
    });

    test('removes what the server refuses from the name', () async {
      answer = (_) => jsonBody(201, accountJson());

      await build().add(
        const AccountDraft(name: 'Trav\u202Eel', kind: AccountKind.card),
      );

      expect(lastRequest().data, {'name': 'Travel', 'kind': 'card'});
    });

    test('a retry after a lost answer uses the same key', () async {
      final repository = build();
      var lost = true;
      answer = (options) {
        if (lost) throw connectionLost(options);
        return jsonBody(201, accountJson());
      };

      await expectLater(
        repository.add(_draft),
        throwsA(isA<NoConnectionException>()),
      );
      lost = false;
      await repository.add(_draft);

      expect(
        [for (final r in server.requests) r.headers['Idempotency-Key']],
        ['"key-1-aaaaaaaaaaaa"', '"key-1-aaaaaaaaaaaa"'],
      );
    });

    test('a name that is taken is a refusal the person can act on', () {
      answer = (_) => jsonBody(
        400,
        errorBody('name_taken', type: 'validation_error', attr: 'name'),
      );

      expect(
        build().add(_draft),
        throwsA(
          isA<AccountRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            AccountRefusal.nameTaken,
          ),
        ),
      );
    });

    test('the limit of accounts is a refusal the person can act on', () {
      answer = (_) => jsonBody(409, errorBody('account_limit_reached'));

      expect(
        build().add(_draft),
        throwsA(
          isA<AccountRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            AccountRefusal.limitReached,
          ),
        ),
      );
    });
  });

  group('update', () {
    test('sends the changes at the version they were made from', () async {
      answer = (_) => jsonBody(200, accountJson(name: 'Main card', version: 4));

      final account = await build().update(
        _id,
        const AccountDraft(name: 'Main card', kind: AccountKind.card),
        version: 3,
      );

      expect(lastRequest().method, 'PATCH');
      expect(lastRequest().path, '/api/v1/accounts/$_id/');
      expect(lastRequest().headers['If-Match'], '"3"');
      expect(lastRequest().data, {'name': 'Main card', 'kind': 'card'});
      expect(account.version, 4);
    });

    test('a version that moved on is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().update(_id, _draft, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('an account that is gone is a stale record too', () {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(
        build().update(_id, _draft, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('a name that is taken is a refusal', () {
      answer = (_) => jsonBody(400, errorBody('name_taken', attr: 'name'));

      expect(
        build().update(_id, _draft, version: 1),
        throwsA(isA<AccountRefusedException>()),
      );
    });
  });

  group('delete', () {
    test('deletes at the version it was made from', () async {
      answer = (_) => jsonBody(204);

      await build().delete(_id, version: 2);

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().path, '/api/v1/accounts/$_id/');
      expect(lastRequest().headers['If-Match'], '"2"');
    });

    test('an account that is already gone is deleted', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      await build().delete(_id, version: 2);
    });

    test('a 404 that is not the documented one is a failure', () {
      answer = (_) => jsonBody(404);

      expect(build().delete(_id, version: 2), throwsA(isA<ServerException>()));
    });

    test('an account with transactions cannot be deleted', () {
      answer = (_) => jsonBody(409, errorBody('account_has_transactions'));

      expect(
        build().delete(_id, version: 2),
        throwsA(isA<AccountInUseException>()),
      );
    });

    test('a version that moved on is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().delete(_id, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  test('tells when this device changed the accounts', () async {
    final repository = build();
    final changes = <void>[];
    final subscription = repository.changes.listen(changes.add);
    addTearDown(subscription.cancel);
    answer = (_) => jsonBody(201, accountJson());

    await repository.add(_draft);
    answer = (_) => jsonBody(204);
    await repository.delete(_id, version: 1);
    await Future<void>.delayed(Duration.zero);

    expect(changes, hasLength(2));
  });
}
