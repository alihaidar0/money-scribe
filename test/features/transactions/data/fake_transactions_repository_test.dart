import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

TransactionDraft coffee({int kopecks = 25000}) {
  return TransactionDraft(
    amount: Money(kopecks, Currency.rub),
    kind: TransactionKind.expense,
    date: DateTime(2026, 10, 20),
    categoryId: 'dining',
    accountId: 'cash',
    note: 'Coffee',
  );
}

void main() {
  late DemoController demo;
  late FakeTransactionsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeTransactionsRepository(demo: demo);
  });

  group('transactions', () {
    test('has the four seeded transactions', () async {
      final items = await repository.transactions();

      expect(items.map((item) => item.id), [
        'seed-scholarship',
        'seed-groceries',
        'seed-coffee',
        'seed-taxi',
      ]);
    });

    test('has none for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect(await repository.transactions(), isEmpty);
    });

    test('reports no connection and a server failure', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await expectLater(
        repository.transactions(),
        throwsA(isA<NoConnectionException>()),
      );

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await expectLater(
        repository.transactions(),
        throwsA(isA<ServerException>()),
      );
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
    test('keeps it after the others, with an id of its own', () async {
      final first = await repository.add(coffee());
      final second = await repository.add(coffee(kopecks: 100));

      expect(first.id, isNot(second.id));
      final items = await repository.transactions();
      expect(items, hasLength(6));
      expect(items.last, second);
    });

    test('works on an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      await repository.add(coffee());

      expect(await repository.transactions(), hasLength(1));
    });

    test('fails when the next save is set to fail', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.add(coffee()),
        throwsA(isA<NoConnectionException>()),
      );
      expect(await repository.transactions(), hasLength(4));
    });
  });

  group('update', () {
    test('replaces it in place', () async {
      final saved = await repository.update('seed-coffee', coffee(kopecks: 1));

      expect(saved.id, 'seed-coffee');
      final items = await repository.transactions();
      expect(items[2].amount, const Money(1, Currency.rub));
      expect(items, hasLength(4));
    });

    test('a transaction that is gone is a server failure', () async {
      await expectLater(
        repository.update('missing', coffee()),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('delete', () {
    test('removes it', () async {
      await repository.delete('seed-taxi');

      expect(await repository.transaction('seed-taxi'), isNull);
      expect(await repository.transactions(), hasLength(3));
    });

    test('deleting what is gone does nothing', () async {
      await repository.delete('missing');

      expect(await repository.transactions(), hasLength(4));
    });
  });

  test('says how the salary is paid, following the demo panel', () async {
    expect(await repository.paymentMode(), PaymentMode.onePayment);

    demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));

    expect(await repository.paymentMode(), PaymentMode.twoPayments);
  });

  test('accounts and categories are the seeded ones', () async {
    final accounts = await FakeAccountsRepository(demo: demo).accounts();
    final categories = await FakeCategoriesRepository(demo: demo).categories();

    expect(accounts.map((account) => account.name), ['Card', 'Cash']);
    expect(categories.map((category) => category.id), contains('groceries'));
  });
}
