import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/features/overview/data/remote/remote_overview_repository.dart';

import '../../../support/fake_http_adapter.dart';
import '../../transactions/data/transactions_json.dart';
import 'overview_json.dart';

Money _usd(int cents) => Money(cents, Currency.usd);

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;

  RemoteOverviewRepository build({Currency currency = Currency.usd}) {
    return RemoteOverviewRepository.create(
      dio: transactionsTestDio(server),
      defaultCurrency: () async => currency,
    );
  }

  setUp(() {
    answer = (_) => jsonBody(200, overviewJson());
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('month', () {
    test('asks for the month in the default currency', () async {
      await build(currency: Currency.eur).month(const YearMonth(2026, 10));

      final request = server.requests.single;
      expect(request.path, '/api/v1/overview/months/2026-10/');
      expect(request.uri.queryParameters['currency'], 'EUR');
    });

    test(
      'keeps the costs negative and the pay and the income positive',
      () async {
        final overview = await build().month(const YearMonth(2026, 10));

        final figures = overview!.total;
        expect(figures.salary, _usd(100000));
        expect(figures.recurringIncome, _usd(10000));
        expect(figures.otherIncome, _usd(5000));
        expect(figures.fixedCosts, _usd(-30000));
        expect(figures.purchases, _usd(-12050));
        expect(figures.income, _usd(115000));
        expect(figures.spent, _usd(-42050));
      },
    );

    test(
      'the debt movement is what was received less what was repaid',
      () async {
        final overview = await build().month(const YearMonth(2026, 10));

        expect(overview!.total.debtMovements, _usd(2500));
      },
    );

    test('shows the balance the server worked out', () async {
      answer = (_) => jsonBody(
        200,
        overviewJson(total: overviewBlockJson(balance: '-12.00')),
      );

      final overview = await build().month(const YearMonth(2026, 10));

      expect(overview!.total.balance, _usd(-1200));
    });

    test('a month paid once has no parts', () async {
      final overview = await build().month(const YearMonth(2026, 10));

      expect(overview!.hasParts, isFalse);
      expect(overview.month, const YearMonth(2026, 10));
    });

    test('a month paid twice has both parts', () async {
      answer = (_) => jsonBody(
        200,
        overviewJson(
          firstPart: overviewBlockJson(salary: '400.00'),
          secondPart: overviewBlockJson(salary: '600.00'),
        ),
      );

      final overview = await build().month(const YearMonth(2026, 10));

      expect(overview!.firstPart!.salary, _usd(40000));
      expect(overview.secondPart!.salary, _usd(60000));
    });

    test('one part without the other is a server failure', () {
      answer = (_) =>
          jsonBody(200, overviewJson(firstPart: overviewBlockJson()));

      expect(
        build().month(const YearMonth(2026, 10)),
        throwsA(isA<ServerException>()),
      );
    });

    test('a month with nothing in it is null', () async {
      answer = (_) => jsonBody(200, overviewJson(hasData: false));

      expect(await build().month(const YearMonth(2026, 10)), isNull);
    });

    test('says when the month has records in other currencies', () async {
      answer = (_) => jsonBody(200, overviewJson(currencies: ['EUR', 'USD']));

      final overview = await build().month(const YearMonth(2026, 10));

      expect(overview!.hasOtherCurrencies, isTrue);
    });

    test('does not say it when every record is in the one currency', () async {
      final overview = await build().month(const YearMonth(2026, 10));

      expect(overview!.hasOtherCurrencies, isFalse);
    });

    test('a month the server does not keep is not asked', () async {
      expect(await build().month(const YearMonth(1999, 12)), isNull);
      expect(await build().month(const YearMonth(2100, 1)), isNull);
      expect(server.requests, isEmpty);
    });

    test('a currency the app does not know is a server failure', () {
      answer = (_) => jsonBody(200, overviewJson(currency: 'XXX'));

      expect(
        build().month(const YearMonth(2026, 10)),
        throwsA(isA<ServerException>()),
      );
    });

    test('an amount that does not fit its currency is a server failure', () {
      answer = (_) => jsonBody(
        200,
        overviewJson(total: overviewBlockJson(salary: '1.234')),
      );

      expect(
        build().month(const YearMonth(2026, 10)),
        throwsA(isA<ServerException>()),
      );
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(
        build().month(const YearMonth(2026, 10)),
        throwsA(isA<NoConnectionException>()),
      );
    });
  });

  group('debtsToRepay', () {
    test(
      'lists the unsettled debts of every currency, overdue first',
      () async {
        answer = (_) => jsonBody(
          200,
          debtsReportJson([
            currencyDebtsJson(
              overdue: [
                debtLineJson(id: 'late', person: 'Maria', remaining: '25.00'),
              ],
              open: [debtLineJson(id: 'sam')],
            ),
            currencyDebtsJson(
              currency: 'EUR',
              open: [
                debtLineJson(
                  id: 'kim',
                  person: 'Kim',
                  direction: 'borrowed',
                  remaining: '9.00',
                ),
              ],
            ),
          ]),
        );

        final debts = await build().debtsToRepay();

        expect(server.requests.single.path, '/api/v1/reports/debts/');
        expect(debts.map((debt) => debt.id), ['late', 'sam', 'kim']);
        expect(debts.map((debt) => debt.status), [
          DebtStatus.overdue,
          DebtStatus.open,
          DebtStatus.open,
        ]);
        expect(debts.first.remaining, _usd(2500));
        expect(debts.last.remaining, const Money(900, Currency.eur));
        expect(debts.last.direction, DebtDirection.borrowed);
      },
    );

    test('is empty when no debt is unsettled', () async {
      answer = (_) => jsonBody(200, debtsReportJson([]));

      expect(await build().debtsToRepay(), isEmpty);
    });
  });

  test('has no pushed changes', () async {
    expect(await build().changes.isEmpty, isTrue);
  });

  test('tells that this device saved something, to reload silently', () async {
    final saves = StreamController<void>();
    addTearDown(saves.close);
    final repository = RemoteOverviewRepository.create(
      dio: transactionsTestDio(server),
      defaultCurrency: () async => Currency.usd,
      changes: saves.stream,
    );
    final changes = <DataChange>[];
    final subscription = repository.changes.listen(changes.add);
    addTearDown(subscription.cancel);

    saves.add(null);
    await pumpEventQueue();

    expect(changes, [DataChange.saved]);
  });
}
