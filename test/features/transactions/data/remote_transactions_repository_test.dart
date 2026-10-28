import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/transactions/data/remote/remote_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';

import '../../../support/fake_http_adapter.dart';
import 'transactions_json.dart';

const _id = '0198f2b0-4e5a-7d12-a3c4-6b7e8f9a0c1d';
const _category = '0198f2a0-0000-7000-8000-000000000001';
const _account = '0198f2a4-7c3e-7b1d-9a52-3e6f1d0c4b21';

TransactionDraft _draft({
  Money amount = const Money(1250, Currency.usd),
  TransactionKind kind = TransactionKind.expense,
  String note = 'Weekly shop',
}) {
  return TransactionDraft(
    amount: amount,
    kind: kind,
    date: DateTime(2026, 10, 24),
    categoryId: _category,
    accountId: _account,
    note: note,
  );
}

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;
  late int keyCount;
  var mode = PaymentMode.onePayment;

  RemoteTransactionsRepository build() {
    return RemoteTransactionsRepository.create(
      dio: transactionsTestDio(server),
      payCycle: () async => switch (mode) {
        PaymentMode.onePayment => const PayCycle.onePayment(),
        PaymentMode.twoPayments => PayCycle.twoPayments(
          firstPayDay: 20,
          secondPayDay: 5,
        ),
      },
      keys: IdempotencyKeys(newKey: () => 'key-${++keyCount}-aaaaaaaaaaaa'),
    );
  }

  RequestOptions lastRequest() => server.requests.last;

  setUp(() {
    keyCount = 0;
    mode = PaymentMode.onePayment;
    answer = (_) => jsonBody(200, transactionJson());
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('transactions', () {
    test('reads a page, newest first as the server sends it', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          transactionJson(),
          transactionJson(
            id: 'income',
            kind: 'income',
            amount: '5000.00',
            currency: 'RUB',
            date: '2026-10-01',
            note: '',
            version: 3,
          ),
        ], next: 'https://api.example.test/api/v1/transactions/?cursor=abc'),
      );

      final page = await build().transactions(const TransactionFilter());

      expect(lastRequest().path, '/api/v1/transactions/');
      expect(page.nextCursor, 'abc');
      expect(page.items, [
        Transaction(
          id: _id,
          amount: const Money(1250, Currency.usd),
          kind: TransactionKind.expense,
          date: DateTime(2026, 10, 24),
          categoryId: _category,
          accountId: _account,
          note: 'Weekly shop',
        ),
        Transaction(
          id: 'income',
          amount: const Money(500000, Currency.rub),
          kind: TransactionKind.income,
          date: DateTime(2026, 10),
          categoryId: _category,
          accountId: _account,
          version: 3,
        ),
      ]);
    });

    test('the last page has no cursor', () async {
      answer = (_) => jsonBody(200, pageJson([transactionJson()]));

      expect(
        (await build().transactions(const TransactionFilter())).nextCursor,
        isNull,
      );
    });

    test('sends the filters as the server takes them', () async {
      answer = (_) => jsonBody(200, pageJson([]));

      await build().transactions(
        TransactionFilter(
          query: '  shop ',
          categoryIds: const {'c1', 'c2'},
          accountIds: const {'a1'},
          from: DateTime(2026, 10),
          to: DateTime(2026, 10, 31),
        ),
        cursor: 'cur',
        pageSize: 30,
      );

      final query = lastRequest().uri.queryParametersAll;
      expect(query['search'], ['shop']);
      expect(query['category_id'], ['c1', 'c2']);
      expect(query['account_id'], ['a1']);
      // A day, not a moment.
      expect(query['date_from'], ['2026-10-01']);
      expect(query['date_to'], ['2026-10-31']);
      expect(query['cursor'], ['cur']);
      expect(query['limit'], ['30']);
    });

    test(
      'sends nothing for a filter that is not set, one letter included',
      () async {
        answer = (_) => jsonBody(200, pageJson([]));

        await build().transactions(const TransactionFilter(query: 'c'));

        final query = lastRequest().uri.queryParametersAll;
        for (final key in [
          'search',
          'category_id',
          'account_id',
          'date_from',
          'date_to',
          'cursor',
        ]) {
          expect(query.containsKey(key), isFalse, reason: key);
        }
      },
    );

    test('sends at most the 20 ids the server takes', () async {
      answer = (_) => jsonBody(200, pageJson([]));

      await build().transactions(
        TransactionFilter(categoryIds: {for (var i = 0; i < 25; i++) 'c$i'}),
      );

      expect(
        lastRequest().uri.queryParametersAll['category_id'],
        hasLength(20),
      );
    });

    test('never follows a next page on another server', () {
      answer = (_) => jsonBody(
        200,
        pageJson([
          transactionJson(),
        ], next: 'https://evil.example.test/api/v1/transactions/?cursor=abc'),
      );

      expect(
        build().transactions(const TransactionFilter()),
        throwsA(isA<ServerException>()),
      );
    });

    test('an amount that does not fit its currency is a server failure', () {
      answer = (_) =>
          jsonBody(200, pageJson([transactionJson(amount: '12.505')]));

      expect(
        build().transactions(const TransactionFilter()),
        throwsA(isA<ServerException>()),
      );
    });

    test('a kind the app does not know is a server failure', () {
      answer = (_) =>
          jsonBody(200, pageJson([transactionJson(kind: 'transfer')]));

      expect(
        build().transactions(const TransactionFilter()),
        throwsA(isA<ServerException>()),
      );
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(
        build().transactions(const TransactionFilter()),
        throwsA(isA<NoConnectionException>()),
      );
    });
  });

  group('dayTotals', () {
    test('reads a total for each currency of a day, signed', () async {
      answer = (_) => jsonBody(
        200,
        pageJson(
          [
            dayTotalJson('2026-09-15', {'KWD': '-1.250', 'USD': '42.50'}),
            dayTotalJson('2026-09-14', {'USD': '-8.00'}),
          ],
          next: 'https://api.example.test/api/v1/reports/day-totals/?cursor=zz',
        ),
      );

      final page = await build().dayTotals(const TransactionFilter());

      expect(lastRequest().path, '/api/v1/reports/day-totals/');
      expect(page.nextCursor, 'zz');
      expect(page.days.first.date, DateTime(2026, 9, 15));
      expect(page.days.first.totals, [
        const Money(-1250, Currency.kwd),
        const Money(4250, Currency.usd),
      ]);
      expect(page.days.last.totals, [const Money(-800, Currency.usd)]);
    });

    test('sends the filters but never the search', () async {
      answer = (_) => jsonBody(200, pageJson([]));

      await build().dayTotals(
        TransactionFilter(
          query: 'shop',
          accountIds: const {'a1'},
          from: DateTime(2026, 10),
        ),
        pageSize: 100,
      );

      final query = lastRequest().uri.queryParametersAll;
      expect(query.containsKey('search'), isFalse);
      expect(query['account_id'], ['a1']);
      expect(query['date_from'], ['2026-10-01']);
      expect(query['limit'], ['100']);
    });

    test('a currency the app does not know is a server failure', () {
      answer = (_) => jsonBody(
        200,
        pageJson([
          dayTotalJson('2026-09-15', {'XXX': '1.00'}),
        ]),
      );

      expect(
        build().dayTotals(const TransactionFilter()),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('transaction', () {
    test('reads one by its id', () async {
      final found = await build().transaction(_id);

      expect(lastRequest().path, '/api/v1/transactions/$_id/');
      expect(found?.note, 'Weekly shop');
    });

    test('is null for one that is not there', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(await build().transaction(_id), isNull);
    });

    test('a 404 that is not the documented one is a failure', () {
      answer = (_) => jsonBody(404);

      expect(build().transaction(_id), throwsA(isA<ServerException>()));
    });
  });

  group('add', () {
    test('sends the transaction as a day, an amount text and a key', () async {
      answer = (_) => jsonBody(201, transactionJson());

      final added = await build().add(_draft());

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/api/v1/transactions/');
      expect(lastRequest().headers['Idempotency-Key'], '"key-1-aaaaaaaaaaaa"');
      expect(lastRequest().data, {
        'kind': 'expense',
        'amount': '12.50',
        'currency': 'USD',
        'date': '2026-10-24',
        'category_id': _category,
        'account_id': _account,
        'note': 'Weekly shop',
      });
      expect(added.id, _id);
    });

    test('removes what the server refuses from the note', () async {
      answer = (_) => jsonBody(201, transactionJson());

      await build().add(_draft(note: 'Shop\u202E now'));

      expect((lastRequest().data as Map)['note'], 'Shop now');
    });

    test('a retry after a lost answer uses the same key', () async {
      final repository = build();
      var lost = true;
      answer = (options) {
        if (lost) throw connectionLost(options);
        return jsonBody(201, transactionJson());
      };

      await expectLater(
        repository.add(_draft()),
        throwsA(isA<NoConnectionException>()),
      );
      lost = false;
      await repository.add(_draft());

      expect(
        [for (final r in server.requests) r.headers['Idempotency-Key']],
        ['"key-1-aaaaaaaaaaaa"', '"key-1-aaaaaaaaaaaa"'],
      );
    });

    test('the next add of the same transaction is a new action', () async {
      final repository = build();
      answer = (_) => jsonBody(201, transactionJson());

      await repository.add(_draft());
      await repository.add(_draft());

      expect(
        [for (final r in server.requests) r.headers['Idempotency-Key']],
        ['"key-1-aaaaaaaaaaaa"', '"key-2-aaaaaaaaaaaa"'],
      );
    });

    Matcher refusal(TransactionRefusal expected) {
      return throwsA(
        isA<TransactionRefusedException>().having(
          (e) => e.refusal,
          'refusal',
          expected,
        ),
      );
    }

    test('the refusals the person can act on', () async {
      answer = (_) => jsonBody(409, errorBody('transaction_limit_reached'));
      await expectLater(
        build().add(_draft()),
        refusal(TransactionRefusal.limitReached),
      );

      answer = (_) =>
          jsonBody(400, errorBody('category_not_allowed', attr: 'category_id'));
      await expectLater(
        build().add(_draft()),
        refusal(TransactionRefusal.categoryNotAllowed),
      );

      answer = (_) =>
          jsonBody(400, errorBody('does_not_exist', attr: 'account_id'));
      await expectLater(
        build().add(_draft()),
        refusal(TransactionRefusal.categoryOrAccountGone),
      );

      answer = (_) =>
          jsonBody(400, errorBody('date_out_of_range', attr: 'date'));
      await expectLater(
        build().add(_draft()),
        refusal(TransactionRefusal.dateOutOfRange),
      );
    });

    test('any other 400 is a server failure', () {
      answer = (_) =>
          jsonBody(400, errorBody('invalid_amount', attr: 'amount'));

      expect(build().add(_draft()), throwsA(isA<ServerException>()));
    });
  });

  group('update', () {
    test('sends the changes at its version, and never the currency', () async {
      answer = (_) =>
          jsonBody(200, transactionJson(amount: '13.00', version: 2));

      final updated = await build().update(
        _id,
        _draft(amount: const Money(1300, Currency.usd)),
        version: 1,
      );

      expect(lastRequest().method, 'PATCH');
      expect(lastRequest().path, '/api/v1/transactions/$_id/');
      expect(lastRequest().headers['If-Match'], '"1"');
      final body = lastRequest().data as Map;
      expect(body.containsKey('currency'), isFalse);
      expect(body['amount'], '13.00');
      expect(body['date'], '2026-10-24');
      expect(updated.version, 2);
    });

    test(
      'a version that moved on, or one that is gone, is a stale record',
      () async {
        answer = (_) => jsonBody(412, errorBody('precondition_failed'));
        await expectLater(
          build().update(_id, _draft(), version: 1),
          throwsA(isA<StaleRecordException>()),
        );

        answer = (_) => jsonBody(404, errorBody('not_found'));
        await expectLater(
          build().update(_id, _draft(), version: 1),
          throwsA(isA<StaleRecordException>()),
        );
      },
    );

    test('a category that does not fit is a refusal', () {
      answer = (_) =>
          jsonBody(400, errorBody('category_not_allowed', attr: 'category_id'));

      expect(
        build().update(_id, _draft(), version: 1),
        throwsA(isA<TransactionRefusedException>()),
      );
    });
  });

  group('delete', () {
    test('deletes at its version', () async {
      answer = (_) => jsonBody(204);

      await build().delete(_id, version: 2);

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().headers['If-Match'], '"2"');
    });

    test('one that is already gone is deleted', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      await build().delete(_id, version: 2);
    });

    test('a version that moved on is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().delete(_id, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  group('payCycle', () {
    test('is how the settings of the account say the salary is paid', () async {
      expect(await build().payCycle(), const PayCycle.onePayment());

      mode = PaymentMode.twoPayments;

      expect(
        await build().payCycle(),
        PayCycle.twoPayments(firstPayDay: 20, secondPayDay: 5),
      );
      // It asks the settings, not the transactions endpoint.
      expect(server.requests, isEmpty);
    });
  });

  test('has no pushed changes', () async {
    expect(await build().changes.isEmpty, isTrue);
  });
}
