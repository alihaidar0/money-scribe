import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

void main() {
  late DemoController demo;
  late FakeTransactionsRepository transactions;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    transactions = FakeTransactionsRepository(demo: demo);
  });

  group('categories', () {
    late FakeCategoriesRepository repository;

    setUp(() {
      repository = FakeCategoriesRepository(
        demo: demo,
        transactions: transactions,
      );
    });

    test('a category the person adds is for expenses and income', () async {
      final category = await repository.add(
        const CategoryDraft(name: 'Pets', icon: CategoryIcon.health),
      );

      expect(category.isCustom, isTrue);
      expect(category.kind, CategoryKind.both);
      expect((await repository.categories()).last, category);
    });

    test('tells when the categories change', () async {
      final changes = <void>[];
      final subscription = repository.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      await repository.add(
        const CategoryDraft(name: 'Pets', icon: CategoryIcon.health),
      );
      await repository.delete('gifts');
      await Future<void>.delayed(Duration.zero);

      expect(changes, hasLength(2));
    });

    test('deleting a category moves its transactions to Other', () async {
      final added = await transactions.add(
        TransactionDraft(
          amount: const Money(10000, Currency.rub),
          kind: TransactionKind.expense,
          date: DateTime(2026, 10, 5),
          categoryId: 'gifts',
          accountId: 'cash',
        ),
      );

      await repository.delete('gifts');

      final moved = await transactions.transaction(added.id);
      expect(moved?.categoryId, 'other');
      expect(
        (await repository.categories()).map((category) => category.id),
        isNot(contains('gifts')),
      );
    });

    test('deleting a category that is gone does nothing', () async {
      await repository.delete('missing');

      expect(await repository.categories(), hasLength(8));
    });

    test('a built-in category can be neither changed nor deleted', () async {
      await expectLater(
        repository.update(
          'groceries',
          const CategoryDraft(name: 'Food', icon: CategoryIcon.dining),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repository.delete('groceries'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('accounts', () {
    late FakeAccountsRepository repository;

    setUp(() {
      repository = FakeAccountsRepository(
        demo: demo,
        transactions: transactions,
      );
    });

    test('an account is added, renamed and deleted', () async {
      final added = await repository.add(
        const AccountDraft(name: 'Savings', kind: AccountKind.other),
      );
      final renamed = await repository.update(
        added.id,
        const AccountDraft(name: 'Piggy bank', kind: AccountKind.cash),
      );
      await repository.delete(added.id);

      expect(renamed.name, 'Piggy bank');
      expect(renamed.kind, AccountKind.cash);
      expect((await repository.accounts()).map((account) => account.name), [
        'Card',
        'Cash',
      ]);
    });

    test('an account with transactions cannot be deleted', () async {
      await expectLater(
        repository.delete('card'),
        throwsA(isA<AccountInUseException>()),
      );
      expect(await repository.accounts(), hasLength(2));
    });

    test('tells when the accounts change', () async {
      final changes = <void>[];
      final subscription = repository.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      await repository.add(
        const AccountDraft(name: 'Savings', kind: AccountKind.other),
      );
      await Future<void>.delayed(Duration.zero);

      expect(changes, hasLength(1));
    });
  });

  group('drafts', () {
    test('a category needs a name that is not too long', () {
      expect(
        CategoryDraft.tryCreate(name: '  ', icon: CategoryIcon.gifts),
        isNull,
      );
      expect(
        CategoryDraft.tryCreate(name: 'x' * 31, icon: CategoryIcon.gifts),
        isNull,
      );
      expect(
        CategoryDraft.tryCreate(name: ' Pets ', icon: CategoryIcon.gifts)?.name,
        'Pets',
      );
    });

    test('an account needs a name that is not too long', () {
      expect(AccountDraft.tryCreate(name: '', kind: AccountKind.card), isNull);
      expect(
        AccountDraft.tryCreate(name: 'x' * 31, kind: AccountKind.card),
        isNull,
      );
      expect(
        AccountDraft.tryCreate(name: ' Wallet ', kind: AccountKind.cash)?.name,
        'Wallet',
      );
    });
  });
}
