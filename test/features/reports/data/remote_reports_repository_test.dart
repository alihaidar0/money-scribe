import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/features/reports/data/remote/remote_reports_repository.dart';

import '../../../support/fake_http_adapter.dart';
import '../../overview/data/overview_json.dart';
import '../../transactions/data/transactions_json.dart';

Money _usd(int cents) => Money(cents, Currency.usd);

void main() {
  late FakeHttpAdapter server;
  late Map<String, Object?> overview;
  late Map<String, Object?> report;
  late ResponseBody Function(RequestOptions options) answer;

  RemoteReportsRepository build({Currency currency = Currency.usd}) {
    return RemoteReportsRepository.create(
      dio: transactionsTestDio(server),
      defaultCurrency: () async => currency,
      partsCycle: () async =>
          PayCycle.twoPayments(firstPayDay: 18, secondPayDay: 3),
    );
  }

  setUp(() {
    overview = overviewJson();
    report = monthReportJson();
    answer = (options) {
      if (options.path.contains('/overview/')) return jsonBody(200, overview);
      return jsonBody(200, report);
    };
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('month', () {
    test(
      'reads the Overview and the month report in the default currency',
      () async {
        await build(currency: Currency.eur).month(const YearMonth(2026, 10));

        expect(
          server.requests.map((r) => r.path),
          unorderedEquals([
            '/api/v1/overview/months/2026-10/',
            '/api/v1/reports/months/2026-10/',
          ]),
        );
        for (final request in server.requests) {
          expect(request.uri.queryParameters['currency'], 'EUR');
        }
      },
    );

    test(
      'the income and the spending are the Overview, not the report',
      () async {
        final report = await build().month(const YearMonth(2026, 10));

        // 1,000.00 pay + 100.00 recurring + 50.00 income transactions.
        expect(report!.total.income, _usd(115000));
        // 300.00 fixed costs + 120.50 purchases.
        expect(report.total.spent, _usd(42050));
      },
    );

    test(
      'the fixed costs are one more slice, adding up to the spending',
      () async {
        final period = (await build().month(const YearMonth(2026, 10)))!.total;

        expect(period.categories.map((c) => (c.name, c.isFixedCosts)), [
          ('Fixed costs', true),
          ('Groceries', false),
          ('Pets', false),
        ]);
        expect(period.categories.first.amount, _usd(30000));
        expect(period.categoriesTotal, period.spent);
      },
    );

    test('a built-in category keeps its key, a custom one has none', () async {
      final period = (await build().month(const YearMonth(2026, 10)))!.total;

      final groceries = period.categories.firstWhere(
        (c) => c.name == 'Groceries',
      );
      final pets = period.categories.firstWhere((c) => c.name == 'Pets');
      expect(groceries.key, 'groceries');
      expect(pets.key, isNull);
    });

    test('there is no slice for fixed costs of nothing', () async {
      overview = overviewJson(total: overviewBlockJson(fixedCosts: '0.00'));

      final period = (await build().month(const YearMonth(2026, 10)))!.total;

      expect(period.categories.any((c) => c.isFixedCosts), isFalse);
    });

    test('a category of nothing is left out', () async {
      report = monthReportJson(
        categories: [
          categorySpendJson(amount: '0.00'),
          categorySpendJson(
            id: 'x',
            key: 'dining',
            name: 'Dining',
            icon: 'dining',
            amount: '10.00',
          ),
        ],
      );

      final period = (await build().month(const YearMonth(2026, 10)))!.total;

      expect(period.categories.map((c) => c.name), contains('Dining'));
      expect(
        period.categories.map((c) => c.name),
        isNot(contains('Groceries')),
      );
    });

    test(
      'equal amounts keep the order of the server, the fixed costs last',
      () async {
        overview = overviewJson(total: overviewBlockJson(fixedCosts: '80.00'));
        report = monthReportJson(
          categories: [
            categorySpendJson(
              id: 'b',
              key: 'dining',
              name: 'Dining',
              icon: 'dining',
            ),
            categorySpendJson(id: 'a'),
          ],
        );

        final period = (await build().month(const YearMonth(2026, 10)))!.total;

        expect(period.categories.map((c) => c.name), [
          'Dining',
          'Groceries',
          'Fixed costs',
        ]);
      },
    );

    test('an icon the app does not know is the plain one', () async {
      report = monthReportJson(categories: [categorySpendJson(icon: 'rocket')]);

      final period = (await build().month(const YearMonth(2026, 10)))!.total;

      expect(
        period.categories.firstWhere((c) => !c.isFixedCosts).icon.name,
        'other',
      );
    });

    test('a month paid twice has a period for each part', () async {
      overview = overviewJson(
        firstPart: overviewBlockJson(salary: '400.00', purchases: '20.00'),
        secondPart: overviewBlockJson(
          salary: '600.00',
          fixedCosts: '0.00',
          purchases: '100.50',
        ),
      );
      report = monthReportJson(
        firstPart: reportSliceJson(
          categories: [categorySpendJson(amount: '20.00')],
        ),
        secondPart: reportSliceJson(
          categories: [categorySpendJson(amount: '100.50')],
        ),
      );

      final month = (await build().month(const YearMonth(2026, 10)))!;

      expect(month.hasParts, isTrue);
      // The parts are cut by the pay days of the settings.
      expect(
        month.cycle,
        PayCycle.twoPayments(firstPayDay: 18, secondPayDay: 3),
      );
      expect(month.firstPart!.spent, _usd(32000));
      expect(month.firstPart!.categories.first.isFixedCosts, isTrue);
      expect(month.secondPart!.spent, _usd(10050));
      expect(month.secondPart!.categories.any((c) => c.isFixedCosts), isFalse);
    });

    test('parts in the Overview but not in the report is a server failure', () {
      overview = overviewJson(
        firstPart: overviewBlockJson(),
        secondPart: overviewBlockJson(),
      );

      expect(
        build().month(const YearMonth(2026, 10)),
        throwsA(isA<ServerException>()),
      );
    });

    test('a month with nothing in it is null', () async {
      overview = overviewJson(hasData: false);

      expect(await build().month(const YearMonth(2026, 10)), isNull);
    });

    test('says when the month has records in other currencies', () async {
      overview = overviewJson(currencies: ['EUR', 'USD']);

      final month = await build().month(const YearMonth(2026, 10));

      expect(month!.hasOtherCurrencies, isTrue);
    });

    test('a month the server does not keep is not asked', () async {
      expect(await build().month(const YearMonth(1999, 12)), isNull);
      expect(server.requests, isEmpty);
    });

    test('if one of the two calls fails, the month fails', () {
      answer = (options) => options.path.contains('/overview/')
          ? jsonBody(200, overview)
          : jsonBody(500, errorBody('server_error'));

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

  group('debts', () {
    test('shows the totals and the debts of the default currency', () async {
      answer = (_) => jsonBody(
        200,
        debtsReportJson([
          currencyDebtsJson(
            owedToYou: '85.00',
            youOwe: '12.00',
            overdue: [
              debtLineJson(
                id: 'late',
                person: 'Maria',
                remaining: '25.00',
                dueDate: '2026-09-30',
              ),
            ],
            open: [debtLineJson(dueDate: null)],
          ),
        ]),
      );

      final report = await build().debts();

      expect(server.requests.single.path, '/api/v1/reports/debts/');
      expect(report.owedToYou, _usd(8500));
      expect(report.youOwe, _usd(1200));
      expect(report.overdue.single.person, 'Maria');
      expect(report.overdue.single.status, DebtStatus.overdue);
      expect(report.overdue.single.dueDate, DateTime(2026, 9, 30));
      expect(report.open.single.status, DebtStatus.open);
      expect(report.open.single.dueDate, isNull);
      expect(report.hasOtherCurrencies, isFalse);
    });

    test('leaves the other currencies out and says that they exist', () async {
      answer = (_) => jsonBody(
        200,
        debtsReportJson([
          currencyDebtsJson(currency: 'EUR', owedToYou: '9.00'),
          currencyDebtsJson(),
        ]),
      );

      final report = await build().debts();

      expect(report.owedToYou, _usd(6000));
      expect(report.open, hasLength(1));
      expect(report.hasOtherCurrencies, isTrue);
    });

    test(
      'with debts only in another currency the totals are nothing',
      () async {
        answer = (_) => jsonBody(
          200,
          debtsReportJson([currencyDebtsJson(currency: 'EUR')]),
        );

        final report = await build().debts();

        expect(report.owedToYou, _usd(0));
        expect(report.isEmpty, isTrue);
        expect(report.hasOtherCurrencies, isTrue);
      },
    );

    test('with no debt at all it is empty', () async {
      answer = (_) => jsonBody(200, debtsReportJson([]));

      final report = await build().debts();

      expect(report.isEmpty, isTrue);
      expect(report.hasOtherCurrencies, isFalse);
    });
  });

  test('has no pushed changes', () async {
    expect(await build().changes.isEmpty, isTrue);
  });

  test('tells that this device saved something, to reload silently', () async {
    final saves = StreamController<void>();
    addTearDown(saves.close);
    final repository = RemoteReportsRepository.create(
      dio: transactionsTestDio(server),
      defaultCurrency: () async => Currency.usd,
      partsCycle: () async =>
          PayCycle.twoPayments(firstPayDay: 18, secondPayDay: 3),
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
