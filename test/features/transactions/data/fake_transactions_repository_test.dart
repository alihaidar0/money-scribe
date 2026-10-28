import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';

TransactionDraft coffee({
  int kopecks = 25000,
  DateTime? date,
  Currency currency = Currency.rub,
  String note = 'Coffee',
}) {
  return TransactionDraft(
    amount: Money(kopecks, currency),
    kind: TransactionKind.expense,
    date: date ?? DateTime(2026, 10, 20),
    categoryId: 'dining',
    accountId: 'cash',
    note: note,
  );
}

const _all = TransactionFilter();

void main() {
  late DemoController demo;
  late FakeTransactionsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeTransactionsRepository(demo: demo);
  });

  Future<List<String>> ids([TransactionFilter filter = _all]) async {
    final page = await repository.transactions(filter);
    return [for (final item in page.items) item.id];
  }

  group('transactions', () {
    test('has the four seeded ones, the newest day first', () async {
      expect(await ids(), [
        'seed-taxi',
        'seed-coffee',
        'seed-groceries',
        'seed-scholarship',
      ]);
    });

    test('has none for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect(await ids(), isEmpty);
    });

    test('reports no connection and a server failure', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await expectLater(
        repository.transactions(_all),
        throwsA(isA<NoConnectionException>()),
      );

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await expectLater(
        repository.transactions(_all),
        throwsA(isA<ServerException>()),
      );
    });

    test('is cut into pages that follow each other', () async {
      final first = await repository.transactions(_all, pageSize: 3);
      expect(first.items.map((item) => item.id), [
        'seed-taxi',
        'seed-coffee',
        'seed-groceries',
      ]);
      expect(first.nextCursor, isNotNull);

      final second = await repository.transactions(
        _all,
        cursor: first.nextCursor,
        pageSize: 3,
      );
      expect(second.items.map((item) => item.id), ['seed-scholarship']);
      expect(second.nextCursor, isNull);
    });

    test('a day shows the transaction added last first', () async {
      await repository.add(coffee(date: DateTime(2026, 10, 19), note: 'One'));
      await repository.add(coffee(date: DateTime(2026, 10, 19), note: 'Two'));

      final page = await repository.transactions(_all);

      expect(page.items.take(3).map((item) => item.note), [
        'Two',
        'One',
        'Taxi',
      ]);
    });

    test(
      'narrows by account, category, days and the words of the note',
      () async {
        expect(await ids(const TransactionFilter(accountIds: {'cash'})), [
          'seed-coffee',
        ]);
        expect(
          await ids(
            const TransactionFilter(categoryIds: {'groceries', 'dining'}),
          ),
          ['seed-coffee', 'seed-groceries'],
        );
        expect(
          await ids(
            TransactionFilter(
              from: DateTime(2026, 10, 5),
              to: DateTime(2026, 10, 17),
            ),
          ),
          ['seed-coffee', 'seed-groceries'],
        );
        expect(await ids(const TransactionFilter(query: ' SHOPPING ')), [
          'seed-groceries',
        ]);
      },
    );

    test('the search looks in the note only, and needs two letters', () async {
      // The category and the account are not searched.
      expect(await ids(const TransactionFilter(query: 'groceries')), isEmpty);
      expect(await ids(const TransactionFilter(query: 'cash')), isEmpty);
      // One letter is not a search.
      expect(await ids(const TransactionFilter(query: 'c')), hasLength(4));
    });
  });

  group('dayTotals', () {
    test(
      'count the income minus the expenses of each day, newest first',
      () async {
        final page = await repository.dayTotals(_all);

        expect(page.days.map((day) => day.date), [
          DateTime(2026, 10, 19),
          DateTime(2026, 10, 17),
          DateTime(2026, 10, 5),
          DateTime(2026, 10),
        ]);
        expect(page.days.first.totals, [const Money(-64000, Currency.rub)]);
        expect(page.days.last.totals, [const Money(500000, Currency.rub)]);
      },
    );

    test('keep a total for each currency of a day', () async {
      await repository.add(
        coffee(
          kopecks: 1250,
          currency: Currency.usd,
          date: DateTime(2026, 10, 19),
        ),
      );
      await repository.add(
        coffee(
          kopecks: 250,
          currency: Currency.usd,
          date: DateTime(2026, 10, 19),
        ),
      );

      final first = (await repository.dayTotals(_all)).days.first;

      expect(first.totals, [
        const Money(-64000, Currency.rub),
        const Money(-1500, Currency.usd),
      ]);
    });

    test('follow the filters but not the search', () async {
      final byAccount = await repository.dayTotals(
        const TransactionFilter(accountIds: {'cash'}),
      );
      expect(byAccount.days.map((day) => day.date), [DateTime(2026, 10, 17)]);

      final searched = await repository.dayTotals(
        const TransactionFilter(query: 'taxi'),
      );
      expect(searched.days, hasLength(4));
    });

    test('are cut into pages of whole days', () async {
      final first = await repository.dayTotals(_all, pageSize: 3);
      expect(first.days, hasLength(3));
      expect(first.nextCursor, isNotNull);

      final second = await repository.dayTotals(
        _all,
        cursor: first.nextCursor,
        pageSize: 3,
      );
      expect(second.days.map((day) => day.date), [DateTime(2026, 10)]);
      expect(second.nextCursor, isNull);
    });
  });

  group('transaction', () {
    test('finds one by its id', () async {
      expect((await repository.transaction('seed-taxi'))?.note, 'Taxi');
    });

    test('is null for an id that does not exist', () async {
      expect(await repository.transaction('missing'), isNull);
    });
  });

  group('add', () {
    test('gives each an id of its own', () async {
      final first = await repository.add(coffee());
      final second = await repository.add(coffee(kopecks: 100));

      expect(first.id, isNot(second.id));
      expect(await ids(), hasLength(6));
    });

    test('works on an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      await repository.add(coffee());

      expect(await ids(), hasLength(1));
    });

    test('fails when the next save is set to fail', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.add(coffee()),
        throwsA(isA<NoConnectionException>()),
      );
      expect(await ids(), hasLength(4));
    });

    test('a person has a limited number of transactions', () async {
      final small = FakeTransactionsRepository(demo: demo, maxTransactions: 4);

      await expectLater(
        small.add(coffee()),
        throwsA(
          isA<TransactionRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            TransactionRefusal.limitReached,
          ),
        ),
      );
    });

    test('a date outside the years the server keeps is refused', () async {
      for (final date in [DateTime(1999, 12, 31), DateTime(2100)]) {
        await expectLater(
          repository.add(coffee(date: date)),
          throwsA(
            isA<TransactionRefusedException>().having(
              (e) => e.refusal,
              'refusal',
              TransactionRefusal.dateOutOfRange,
            ),
          ),
          reason: '$date',
        );
      }
    });
  });

  group('update', () {
    test('replaces it and moves the version on', () async {
      final saved = await repository.update(
        'seed-coffee',
        coffee(kopecks: 1),
        version: 1,
      );

      expect(saved.id, 'seed-coffee');
      expect(saved.version, 2);
      expect(
        (await repository.transaction('seed-coffee'))?.amount.minorUnits,
        1,
      );
    });

    test('a version that moved on is a stale record', () async {
      await repository.update('seed-coffee', coffee(kopecks: 1), version: 1);

      await expectLater(
        repository.update('seed-coffee', coffee(kopecks: 2), version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('a transaction that is gone is a stale record too', () async {
      await expectLater(
        repository.update('missing', coffee(), version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  group('delete', () {
    test('removes it', () async {
      await repository.delete('seed-taxi', version: 1);

      expect(await repository.transaction('seed-taxi'), isNull);
      expect(await ids(), hasLength(3));
    });

    test('a version that moved on is a stale record', () async {
      await expectLater(
        repository.delete('seed-taxi', version: 2),
        throwsA(isA<StaleRecordException>()),
      );
      expect(await ids(), hasLength(4));
    });

    test('deleting what is gone does nothing', () async {
      await repository.delete('missing', version: 1);

      expect(await ids(), hasLength(4));
    });
  });

  test('moving a category moves the version on', () async {
    repository.moveCategory(from: 'transport', to: 'other');

    final moved = await repository.transaction('seed-taxi');
    expect(moved?.categoryId, 'other');
    expect(moved?.version, 2);
  });

  test('says how the salary is paid, following the demo panel', () async {
    expect(await repository.payCycle(), const PayCycle.onePayment());

    demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));

    expect(
      await repository.payCycle(),
      PayCycle.twoPayments(firstPayDay: 20, secondPayDay: 5),
    );
  });

  test('accounts and categories are the seeded ones', () async {
    final accounts = await FakeAccountsRepository(demo: demo).accounts();
    final categories = await FakeCategoriesRepository(demo: demo).categories();

    expect(accounts.map((account) => account.name), ['Card', 'Cash']);
    expect(categories.map((category) => category.id), contains('groceries'));
  });
}
