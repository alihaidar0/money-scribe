import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/features/salary/data/remote/remote_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_copy_refusal.dart';

import '../../../support/fake_http_adapter.dart';
import 'salary_json.dart';

const _october = YearMonth(2026, 10);
const _id = '0192a000-0000-7000-8000-000000000001';

const _scholarship = FixedItemDraft(
  name: 'Scholarship',
  amount: Money(500000, Currency.rub),
  kind: FixedItemKind.income,
);

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;
  late int keyCount;

  RemoteFixedItemsRepository build() {
    return RemoteFixedItemsRepository.create(
      dio: salaryTestDio(server),
      keys: IdempotencyKeys(newKey: () => 'key-${++keyCount}-aaaaaaaaaaaa'),
    );
  }

  RequestOptions lastRequest() => server.requests.last;

  setUp(() {
    keyCount = 0;
    answer = (_) => jsonBody(200, fixedItemJson());
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('items', () {
    test('reads the items of the month', () async {
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(
          fixedItems: [
            fixedItemJson(),
            fixedItemJson(
              id: 'second',
              name: 'Rent',
              amount: '30000.00',
              kind: 'expense',
              part: 'second',
              version: 3,
            ),
          ],
        ),
      );

      final items = await build().items(_october);

      expect(lastRequest().path, '/api/v1/salary/months/2026-10/');
      expect(items, [
        const FixedItem(
          id: _id,
          name: 'Scholarship',
          amount: Money(500000, Currency.rub),
          kind: FixedItemKind.income,
          part: FixedItemPart.first,
        ),
        const FixedItem(
          id: 'second',
          name: 'Rent',
          amount: Money(3000000, Currency.rub),
          kind: FixedItemKind.expense,
          part: FixedItemPart.second,
          version: 3,
        ),
      ]);
    });

    test('a month that was not saved has no items', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(await build().items(_october), isEmpty);
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().items(_october), throwsA(isA<NoConnectionException>()));
    });
  });

  group('add', () {
    test('sends the item with a key for this action', () async {
      answer = (_) => jsonBody(201, fixedItemJson());

      final item = await build().add(_october, _scholarship);

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/api/v1/salary/months/2026-10/fixed-items/');
      expect(lastRequest().headers['Idempotency-Key'], '"key-1-aaaaaaaaaaaa"');
      expect(lastRequest().data, {
        'name': 'Scholarship',
        'amount': '5000.00',
        'kind': 'income',
        'currency': 'RUB',
        'part': 'first',
      });
      expect(item.id, _id);
      expect(item.amount, _scholarship.amount);
    });

    test('a retry after a lost answer sends the same key', () async {
      final repository = build();
      var lost = true;
      answer = (options) {
        if (lost) throw connectionLost(options);
        return jsonBody(201, fixedItemJson());
      };

      await expectLater(
        repository.add(_october, _scholarship),
        throwsA(isA<NoConnectionException>()),
      );
      lost = false;
      await repository.add(_october, _scholarship);

      final keys = [
        for (final request in server.requests)
          request.headers['Idempotency-Key'],
      ];
      expect(keys, ['"key-1-aaaaaaaaaaaa"', '"key-1-aaaaaaaaaaaa"']);
    });

    test(
      'the next add of the same item is a new action with a new key',
      () async {
        final repository = build();
        answer = (_) => jsonBody(201, fixedItemJson());

        await repository.add(_october, _scholarship);
        await repository.add(_october, _scholarship);

        final keys = [
          for (final request in server.requests)
            request.headers['Idempotency-Key'],
        ];
        expect(keys, ['"key-1-aaaaaaaaaaaa"', '"key-2-aaaaaaaaaaaa"']);
      },
    );

    test('a first try that is still running is reported', () {
      answer = (_) => jsonBody(409, errorBody('idempotency_in_progress'));

      expect(
        build().add(_october, _scholarship),
        throwsA(isA<RequestInProgressException>()),
      );
    });

    test('a month that is not saved is a failure', () {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(
        build().add(_october, _scholarship),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('update', () {
    test('replaces the item at the version that was read', () async {
      answer = (_) => jsonBody(
        200,
        fixedItemJson(name: 'Grant', amount: '6000.00', version: 2),
      );

      final item = await build().update(
        _october,
        _id,
        const FixedItemDraft(
          name: 'Grant',
          amount: Money(600000, Currency.rub),
          kind: FixedItemKind.income,
          part: FixedItemPart.second,
        ),
        version: 1,
      );

      expect(lastRequest().method, 'PATCH');
      expect(lastRequest().path, '/api/v1/salary/fixed-items/$_id/');
      expect(lastRequest().headers['If-Match'], '"1"');
      expect(lastRequest().data, {
        'name': 'Grant',
        'amount': '6000.00',
        'kind': 'income',
        'currency': 'RUB',
        'part': 'second',
      });
      expect(item.version, 2);
      expect(item.name, 'Grant');
    });

    test('an item changed meanwhile elsewhere is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().update(_october, _id, _scholarship, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('an item deleted meanwhile elsewhere is a stale record', () {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(
        build().update(_october, _id, _scholarship, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  group('delete', () {
    test('deletes at the version that was read', () async {
      answer = (_) => ResponseBody.fromString('', 204);

      await build().delete(_october, _id, version: 2);

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().path, '/api/v1/salary/fixed-items/$_id/');
      expect(lastRequest().headers['If-Match'], '"2"');
    });

    test('an item that is gone is already deleted', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      await build().delete(_october, _id, version: 2);
    });

    test('an item changed meanwhile elsewhere is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().delete(_october, _id, version: 2),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  group('copyFromPrevious', () {
    Matcher refusedWith(FixedItemsCopyRefusal refusal) {
      return throwsA(
        isA<FixedItemsCopyRefusedException>().having(
          (e) => e.refusal,
          'refusal',
          refusal,
        ),
      );
    }

    test('asks the server to copy, with a key for this action', () async {
      answer = (_) => jsonBody(
        200,
        salaryMonthJson(
          fixedItems: [
            fixedItemJson(),
            fixedItemJson(id: 'second', name: 'Rent', kind: 'expense'),
          ],
        ),
      );

      final items = await build().copyFromPrevious(_october);

      expect(lastRequest().method, 'POST');
      expect(
        lastRequest().path,
        '/api/v1/salary/months/2026-10/fixed-items/copy/',
      );
      expect(lastRequest().headers['Idempotency-Key'], '"key-1-aaaaaaaaaaaa"');
      // No `from`: the server takes the most recent saved month before it.
      expect(lastRequest().data, <String, Object?>{});
      expect(items.map((item) => item.name), ['Scholarship', 'Rent']);
    });

    test('a retry after a lost answer sends the same key', () async {
      final repository = build();
      var lost = true;
      answer = (options) {
        if (lost) throw connectionLost(options);
        return jsonBody(200, salaryMonthJson());
      };

      await expectLater(
        repository.copyFromPrevious(_october),
        throwsA(isA<NoConnectionException>()),
      );
      lost = false;
      await repository.copyFromPrevious(_october);

      final keys = [
        for (final request in server.requests)
          request.headers['Idempotency-Key'],
      ];
      expect(keys, ['"key-1-aaaaaaaaaaaa"', '"key-1-aaaaaaaaaaaa"']);
    });

    test('the next copy is a new action with a new key', () async {
      final repository = build();
      answer = (_) => jsonBody(200, salaryMonthJson());

      await repository.copyFromPrevious(_october);
      await repository.copyFromPrevious(_october);

      final keys = [
        for (final request in server.requests)
          request.headers['Idempotency-Key'],
      ];
      expect(keys, ['"key-1-aaaaaaaaaaaa"', '"key-2-aaaaaaaaaaaa"']);
    });

    test('no earlier saved month is a refusal', () {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(
        build().copyFromPrevious(_october),
        refusedWith(FixedItemsCopyRefusal.noEarlierMonth),
      );
    });

    test('too many items is a refusal', () {
      answer = (_) => jsonBody(409, errorBody('fixed_item_limit_reached'));

      expect(
        build().copyFromPrevious(_october),
        refusedWith(FixedItemsCopyRefusal.limitReached),
      );
    });

    test('another currency is a refusal', () {
      answer = (_) => jsonBody(400, errorBody('currency_mismatch'));

      expect(
        build().copyFromPrevious(_october),
        refusedWith(FixedItemsCopyRefusal.currencyMismatch),
      );
    });

    test('a first try that is still running is reported', () {
      answer = (_) => jsonBody(409, errorBody('idempotency_in_progress'));

      expect(
        build().copyFromPrevious(_october),
        throwsA(isA<RequestInProgressException>()),
      );
    });

    test('a refusal ends the action, so the next try has a new key', () async {
      final repository = build();
      answer = (_) => jsonBody(404, errorBody('not_found'));
      await expectLater(
        repository.copyFromPrevious(_october),
        refusedWith(FixedItemsCopyRefusal.noEarlierMonth),
      );

      answer = (_) => jsonBody(200, salaryMonthJson());
      await repository.copyFromPrevious(_october);

      final keys = [
        for (final request in server.requests)
          request.headers['Idempotency-Key'],
      ];
      expect(keys, ['"key-1-aaaaaaaaaaaa"', '"key-2-aaaaaaaaaaaa"']);
    });

    test('a server failure and a busy server are not refusals', () async {
      answer = (_) => jsonBody(500, errorBody('server_error'));
      await expectLater(
        build().copyFromPrevious(_october),
        throwsA(isA<ServerException>()),
      );

      answer = (_) => jsonBody(503, errorBody('server_error'));
      await expectLater(
        build().copyFromPrevious(_october),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });
  });
}
