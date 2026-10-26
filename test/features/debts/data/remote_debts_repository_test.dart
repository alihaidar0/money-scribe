import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/features/debts/data/remote/remote_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

import '../../../support/fake_http_adapter.dart';
import '../../transactions/data/transactions_json.dart';
import 'debts_json.dart';

const _id = '0198f2c0-4e5a-7d12-a3c4-6b7e8f9a0c1d';
const _repayment = '0198f2c1-0000-7000-8000-0000000000a1';

Money _usd(int cents) => Money(cents, Currency.usd);

DebtDraft _draft({
  DebtDirection direction = DebtDirection.lent,
  String person = 'Sam',
  Money? amount,
  DateTime? dueDate,
  String note = 'Lunch money',
}) {
  return DebtDraft(
    direction: direction,
    person: person,
    amount: amount ?? _usd(10000),
    startDate: DateTime(2026, 10),
    dueDate: dueDate,
    note: note,
  );
}

RepaymentDraft _payment([int cents = 2500]) {
  return RepaymentDraft(amount: _usd(cents), date: DateTime(2026, 10, 20));
}

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;
  late int keyCount;

  RemoteDebtsRepository build({Currency currency = Currency.usd}) {
    return RemoteDebtsRepository.create(
      dio: transactionsTestDio(server),
      defaultCurrency: () async => currency,
      keys: IdempotencyKeys(newKey: () => 'key-${++keyCount}-aaaaaaaaaaaa'),
    );
  }

  RequestOptions lastRequest() => server.requests.last;

  setUp(() {
    keyCount = 0;
    answer = (_) => jsonBody(200, debtJson());
    server = FakeHttpAdapter((options) => answer(options));
  });

  Matcher refusal(DebtRefusal expected) {
    return throwsA(
      isA<DebtRefusedException>().having((e) => e.refusal, 'refusal', expected),
    );
  }

  group('debts', () {
    test('reads the debt with its repayments and versions', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          debtJson(
            repayments: [
              repaymentJson(version: 3),
              repaymentJson(id: 'second', amount: '10.00', date: '2026-10-15'),
            ],
            repaid: '50.00',
            remaining: '50.00',
            version: 4,
          ),
        ]),
      );

      final debts = await build().debts();

      expect(lastRequest().path, '/api/v1/debts/');
      expect(lastRequest().uri.queryParameters['limit'], '100');
      expect(debts.single, isA<Debt>());
      final debt = debts.single;
      expect(debt.id, _id);
      expect(debt.direction, DebtDirection.lent);
      expect(debt.person, 'Sam');
      expect(debt.amount, _usd(10000));
      expect(debt.startDate, DateTime(2026, 10));
      expect(debt.dueDate, DateTime(2026, 10, 31));
      expect(debt.note, 'Lunch money');
      expect(debt.version, 4);
      expect(debt.repaid, _usd(5000));
      expect(debt.remaining, _usd(5000));
      expect(debt.repayments.map((r) => (r.id, r.version)), [
        (_repayment, 3),
        ('second', 1),
      ]);
      expect(debt.repayments.first.date, DateTime(2026, 10, 12));
    });

    test('has no due day when the server sends none', () async {
      answer = (_) => jsonBody(200, pageJson([debtJson(dueDate: null)]));

      expect((await build().debts()).single.dueDate, isNull);
    });

    test('reads every page and hands the debts over oldest first', () async {
      answer = (options) {
        final cursor = options.uri.queryParameters['cursor'];
        return switch (cursor) {
          null => jsonBody(
            200,
            pageJson([
              debtJson(id: 'newest'),
              debtJson(id: 'middle'),
            ], next: 'https://api.example.test/api/v1/debts/?cursor=p2'),
          ),
          'p2' => jsonBody(200, pageJson([debtJson(id: 'oldest')])),
          _ => jsonBody(400),
        };
      };

      final debts = await build().debts();

      expect(debts.map((debt) => debt.id), ['oldest', 'middle', 'newest']);
      expect(server.requests, hasLength(2));
    });

    test('does not follow a page address on another server', () {
      answer = (_) => jsonBody(
        200,
        pageJson([debtJson()], next: 'https://elsewhere.example/api?cursor=x'),
      );

      expect(build().debts(), throwsA(isA<ServerException>()));
    });

    test('a server that keeps giving pages is a failure', () {
      answer = (_) => jsonBody(
        200,
        pageJson([
          debtJson(),
        ], next: 'https://api.example.test/api/v1/debts/?cursor=${keyCount++}'),
      );

      expect(build().debts(), throwsA(isA<ServerException>()));
      expect(server.requests.length, lessThanOrEqualTo(5));
    });

    test('keeps the status the server worked out', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          debtJson(status: 'overdue'),
          debtJson(status: 'settled'),
          debtJson(status: 'later'),
        ]),
      );

      final debts = await build().debts();

      expect(debts.map((debt) => debt.reportedStatus), [
        null,
        DebtStatus.settled,
        DebtStatus.overdue,
      ]);
    });

    test('a currency or a direction the app does not know is a failure', () {
      answer = (_) => jsonBody(200, pageJson([debtJson(currency: 'XXX')]));
      expect(build().debts(), throwsA(isA<ServerException>()));

      answer = (_) => jsonBody(200, pageJson([debtJson(direction: 'gift')]));
      expect(build().debts(), throwsA(isA<ServerException>()));
    });

    test('an amount that does not fit its currency is a failure', () {
      answer = (_) => jsonBody(200, pageJson([debtJson(amount: '1.234')]));

      expect(build().debts(), throwsA(isA<ServerException>()));
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().debts(), throwsA(isA<NoConnectionException>()));
    });
  });

  group('debt', () {
    test('reads one by its id', () async {
      final found = await build().debt(_id);

      expect(lastRequest().path, '/api/v1/debts/$_id/');
      expect(found?.person, 'Sam');
    });

    test('is null for one that is not there', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(await build().debt(_id), isNull);
    });

    test('a 404 that is not the documented one is a failure', () {
      answer = (_) => jsonBody(404);

      expect(build().debt(_id), throwsA(isA<ServerException>()));
    });
  });

  group('add', () {
    test('sends the debt as days, an amount text and a key', () async {
      answer = (_) => jsonBody(201, debtJson(repayments: []));

      final added = await build().add(_draft(dueDate: DateTime(2026, 10, 31)));

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/api/v1/debts/');
      expect(lastRequest().headers['Idempotency-Key'], '"key-1-aaaaaaaaaaaa"');
      expect(lastRequest().data, {
        'direction': 'lent',
        'person': 'Sam',
        'amount': '100.00',
        'currency': 'USD',
        'start_date': '2026-10-01',
        'due_date': '2026-10-31',
        'note': 'Lunch money',
      });
      expect(added.id, _id);
    });

    test('leaves the due day out when there is none', () async {
      answer = (_) => jsonBody(201, debtJson());

      await build().add(_draft());

      expect((lastRequest().data as Map).containsKey('due_date'), isFalse);
    });

    test('removes what the server refuses from the person and note', () async {
      answer = (_) => jsonBody(201, debtJson());

      await build().add(_draft(person: 'Sam\u202E', note: 'Lunch\nmoney'));

      final body = lastRequest().data as Map;
      expect(body['person'], 'Sam');
      expect(body['note'], 'Lunch money');
    });

    test('a retry after a lost answer uses the same key', () async {
      final repository = build();
      var lost = true;
      answer = (options) {
        if (lost) throw connectionLost(options);
        return jsonBody(201, debtJson());
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

    test('the next add of the same debt is a new action', () async {
      final repository = build();
      answer = (_) => jsonBody(201, debtJson());

      await repository.add(_draft());
      await repository.add(_draft());

      expect(
        [for (final r in server.requests) r.headers['Idempotency-Key']],
        ['"key-1-aaaaaaaaaaaa"', '"key-2-aaaaaaaaaaaa"'],
      );
    });

    test('the refusals the person can act on', () async {
      answer = (_) => jsonBody(409, errorBody('debt_limit_reached'));
      await expectLater(
        build().add(_draft()),
        refusal(DebtRefusal.limitReached),
      );

      answer = (_) => jsonBody(400, errorBody('due_before_start'));
      await expectLater(
        build().add(_draft()),
        refusal(DebtRefusal.dueBeforeStart),
      );

      answer = (_) => jsonBody(400, errorBody('date_out_of_range'));
      await expectLater(
        build().add(_draft()),
        refusal(DebtRefusal.dateOutOfRange),
      );
    });

    test('any other 400 is a server failure', () {
      answer = (_) => jsonBody(400, errorBody('invalid_amount'));

      expect(build().add(_draft()), throwsA(isA<ServerException>()));
    });
  });

  group('update', () {
    test(
      'sends the changes at its version, never direction or currency',
      () async {
        answer = (_) => jsonBody(200, debtJson(person: 'Lee', version: 2));

        final updated = await build().update(
          _id,
          _draft(person: 'Lee', dueDate: DateTime(2026, 11)),
          version: 1,
        );

        expect(lastRequest().method, 'PATCH');
        expect(lastRequest().path, '/api/v1/debts/$_id/');
        expect(lastRequest().headers['If-Match'], '"1"');
        expect(lastRequest().data, {
          'person': 'Lee',
          'amount': '100.00',
          'start_date': '2026-10-01',
          'due_date': '2026-11-01',
          'note': 'Lunch money',
        });
        expect(updated.version, 2);
      },
    );

    test('takes the due day away by sending null', () async {
      answer = (_) => jsonBody(200, debtJson(dueDate: null, version: 2));

      await build().update(_id, _draft(), version: 1);

      final body = lastRequest().data as Map;
      expect(body.containsKey('due_date'), isTrue);
      expect(body['due_date'], isNull);
    });

    test('does not change how the other calls leave nulls out', () async {
      final repository = build();
      answer = (_) => jsonBody(201, debtJson());

      await repository.update(_id, _draft(), version: 1);
      await repository.add(_draft());

      expect((lastRequest().data as Map).containsKey('due_date'), isFalse);
    });

    test('a version that moved on, or one that is gone, is stale', () async {
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
    });

    test('the refusals the person can act on', () async {
      answer = (_) => jsonBody(400, errorBody('amount_below_repaid'));
      await expectLater(
        build().update(_id, _draft(), version: 1),
        refusal(DebtRefusal.amountBelowRepaid),
      );

      answer = (_) => jsonBody(400, errorBody('start_after_repayment'));
      await expectLater(
        build().update(_id, _draft(), version: 1),
        refusal(DebtRefusal.startAfterRepayment),
      );
    });
  });

  group('delete', () {
    test('deletes at its version', () async {
      answer = (_) => jsonBody(204);

      await build().delete(_id, version: 2);

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().path, '/api/v1/debts/$_id/');
      expect(lastRequest().headers['If-Match'], '"2"');
    });

    test('one that is already gone is deleted', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      await build().delete(_id, version: 2);
    });

    test('a version that moved on is stale', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().delete(_id, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  group('addRepayment', () {
    test('sends a day, an amount text and a key, and gets the debt', () async {
      answer = (_) => jsonBody(
        201,
        debtJson(
          repayments: [
            repaymentJson(),
            repaymentJson(id: 'new', amount: '25.00', date: '2026-10-20'),
          ],
          repaid: '65.00',
          remaining: '35.00',
        ),
      );

      final debt = await build().addRepayment(_id, _payment());

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/api/v1/debts/$_id/repayments/');
      expect(lastRequest().headers['Idempotency-Key'], '"key-1-aaaaaaaaaaaa"');
      expect(lastRequest().data, {'amount': '25.00', 'date': '2026-10-20'});
      expect(debt.remaining, _usd(3500));
      expect(debt.repayments, hasLength(2));
      // A repayment does not change the version of its debt.
      expect(debt.version, 1);
    });

    test('a retry after a lost answer uses the same key', () async {
      final repository = build();
      var lost = true;
      answer = (options) {
        if (lost) throw connectionLost(options);
        return jsonBody(201, debtJson());
      };

      await expectLater(
        repository.addRepayment(_id, _payment()),
        throwsA(isA<NoConnectionException>()),
      );
      lost = false;
      await repository.addRepayment(_id, _payment());

      expect(
        [for (final r in server.requests) r.headers['Idempotency-Key']],
        ['"key-1-aaaaaaaaaaaa"', '"key-1-aaaaaaaaaaaa"'],
      );
    });

    test('more than what is left is a refusal with what is left', () async {
      answer = (_) => jsonBody(
        400,
        errorBody(
          'exceeds_remaining',
          attr: 'amount',
          extra: {'remaining': '60.00'},
        ),
      );

      await expectLater(
        build().addRepayment(_id, _payment(9000)),
        throwsA(
          isA<DebtRefusedException>()
              .having((e) => e.refusal, 'refusal', DebtRefusal.exceedsRemaining)
              .having((e) => e.remaining, 'remaining', _usd(6000)),
        ),
      );
    });

    test(
      'a refusal for being too much without the amount still stands',
      () async {
        answer = (_) =>
            jsonBody(400, errorBody('exceeds_remaining', attr: 'amount'));

        await expectLater(
          build().addRepayment(_id, _payment(9000)),
          throwsA(
            isA<DebtRefusedException>()
                .having(
                  (e) => e.refusal,
                  'refusal',
                  DebtRefusal.exceedsRemaining,
                )
                .having((e) => e.remaining, 'remaining', isNull),
          ),
        );
      },
    );

    test('the other refusals the person can act on', () async {
      answer = (_) => jsonBody(400, errorBody('repayment_before_start'));
      await expectLater(
        build().addRepayment(_id, _payment()),
        refusal(DebtRefusal.repaymentBeforeStart),
      );

      answer = (_) => jsonBody(409, errorBody('repayment_limit_reached'));
      await expectLater(
        build().addRepayment(_id, _payment()),
        refusal(DebtRefusal.repaymentLimitReached),
      );
    });

    test('a debt that is gone is a stale record', () {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(
        build().addRepayment(_id, _payment()),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  group('updateRepayment', () {
    test('sends the changes at the version of the repayment', () async {
      answer = (_) => jsonBody(200, debtJson());

      await build().updateRepayment(_id, _repayment, _payment(), version: 3);

      expect(lastRequest().method, 'PATCH');
      expect(lastRequest().path, '/api/v1/debts/$_id/repayments/$_repayment/');
      expect(lastRequest().headers['If-Match'], '"3"');
      expect(lastRequest().data, {'amount': '25.00', 'date': '2026-10-20'});
    });

    test('a version that moved on, or one that is gone, is stale', () async {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));
      await expectLater(
        build().updateRepayment(_id, _repayment, _payment(), version: 3),
        throwsA(isA<StaleRecordException>()),
      );

      answer = (_) => jsonBody(404, errorBody('not_found'));
      await expectLater(
        build().updateRepayment(_id, _repayment, _payment(), version: 3),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('more than what is left is a refusal', () {
      answer = (_) => jsonBody(
        400,
        errorBody('exceeds_remaining', extra: {'remaining': '60.00'}),
      );

      expect(
        build().updateRepayment(_id, _repayment, _payment(), version: 1),
        refusal(DebtRefusal.exceedsRemaining),
      );
    });
  });

  group('deleteRepayment', () {
    test('deletes at the version of the repayment and gets the debt', () async {
      answer = (_) => jsonBody(
        200,
        debtJson(repayments: [], repaid: '0.00', remaining: '100.00'),
      );

      final debt = await build().deleteRepayment(_id, _repayment, version: 3);

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().path, '/api/v1/debts/$_id/repayments/$_repayment/');
      expect(lastRequest().headers['If-Match'], '"3"');
      expect(debt.repayments, isEmpty);
      expect(debt.remaining, _usd(10000));
    });

    test('one that is already gone answers with the debt as it is', () async {
      answer = (options) => options.method == 'DELETE'
          ? jsonBody(404, errorBody('not_found'))
          : jsonBody(200, debtJson(repayments: []));

      final debt = await build().deleteRepayment(_id, _repayment, version: 3);

      expect(debt.repayments, isEmpty);
      expect(server.requests.map((r) => r.method), ['DELETE', 'GET']);
    });

    test('with its debt gone too, it is a stale record', () {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      expect(
        build().deleteRepayment(_id, _repayment, version: 3),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('a version that moved on is stale', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().deleteRepayment(_id, _repayment, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  test('the default currency is the one of the settings', () async {
    expect(await build(currency: Currency.eur).defaultCurrency(), Currency.eur);
    // It asks the settings, not the debts endpoint.
    expect(server.requests, isEmpty);
  });

  test('has no pushed changes', () async {
    expect(await build().changes.isEmpty, isTrue);
  });
}
