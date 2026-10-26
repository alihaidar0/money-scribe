import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
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

    test('a name is used once, in any case, built-in names included', () async {
      for (final name in ['gifts', 'GIFTS', 'groceries', 'Groceries']) {
        await expectLater(
          repository.add(CategoryDraft(name: name, icon: CategoryIcon.health)),
          throwsA(
            isA<CategoryRefusedException>().having(
              (e) => e.refusal,
              'refusal',
              CategoryRefusal.nameTaken,
            ),
          ),
          reason: name,
        );
      }
    });

    test('a person has at most 50 categories of their own', () async {
      for (var i = 1; i < FakeCategoriesRepository.maxCustom; i++) {
        await repository.add(
          CategoryDraft(name: 'Own $i', icon: CategoryIcon.health),
        );
      }

      await expectLater(
        repository.add(
          const CategoryDraft(name: 'One more', icon: CategoryIcon.health),
        ),
        throwsA(
          isA<CategoryRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            CategoryRefusal.limitReached,
          ),
        ),
      );
    });

    test('a change moves the version on and a stale one is refused', () async {
      final changed = await repository.update(
        'gifts',
        const CategoryDraft(name: 'Presents', icon: CategoryIcon.gifts),
        version: 1,
      );

      expect(changed.version, 2);
      await expectLater(
        repository.update(
          'gifts',
          const CategoryDraft(name: 'Again', icon: CategoryIcon.gifts),
          version: 1,
        ),
        throwsA(isA<StaleRecordException>()),
      );
      await expectLater(
        repository.delete('gifts', version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('tells when the categories change', () async {
      final changes = <void>[];
      final subscription = repository.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      await repository.add(
        const CategoryDraft(name: 'Pets', icon: CategoryIcon.health),
      );
      await repository.delete('gifts', version: 1);
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

      await repository.delete('gifts', version: 1);

      final moved = await transactions.transaction(added.id);
      expect(moved?.categoryId, 'other');
      expect(
        (await repository.categories()).map((category) => category.id),
        isNot(contains('gifts')),
      );
    });

    test('deleting a category that is gone does nothing', () async {
      await repository.delete('missing', version: 1);

      expect(await repository.categories(), hasLength(8));
    });

    test('a built-in category can be neither changed nor deleted', () async {
      await expectLater(
        repository.update(
          'groceries',
          const CategoryDraft(name: 'Food', icon: CategoryIcon.dining),
          version: 1,
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repository.delete('groceries', version: 1),
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
        version: added.version,
      );
      await repository.delete(added.id, version: renamed.version);

      expect(renamed.name, 'Piggy bank');
      expect(renamed.kind, AccountKind.cash);
      expect((await repository.accounts()).map((account) => account.name), [
        'Card',
        'Cash',
      ]);
    });

    test('an account with transactions cannot be deleted', () async {
      await expectLater(
        repository.delete('card', version: 1),
        throwsA(isA<AccountInUseException>()),
      );
      expect(await repository.accounts(), hasLength(2));
    });

    test('a name is used once, in any case', () async {
      for (final name in ['Card', 'CASH']) {
        await expectLater(
          repository.add(AccountDraft(name: name, kind: AccountKind.other)),
          throwsA(
            isA<AccountRefusedException>().having(
              (e) => e.refusal,
              'refusal',
              AccountRefusal.nameTaken,
            ),
          ),
          reason: name,
        );
      }
    });

    test('a person has at most 20 accounts', () async {
      for (var i = 2; i < FakeAccountsRepository.maxAccounts; i++) {
        await repository.add(
          AccountDraft(name: 'Account $i', kind: AccountKind.other),
        );
      }

      await expectLater(
        repository.add(
          const AccountDraft(name: 'One more', kind: AccountKind.other),
        ),
        throwsA(
          isA<AccountRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            AccountRefusal.limitReached,
          ),
        ),
      );
    });

    test('a change moves the version on and a stale one is refused', () async {
      final changed = await repository.update(
        'cash',
        const AccountDraft(name: 'Wallet', kind: AccountKind.cash),
        version: 1,
      );

      expect(changed.version, 2);
      await expectLater(
        repository.update(
          'cash',
          const AccountDraft(name: 'Again', kind: AccountKind.cash),
          version: 1,
        ),
        throwsA(isA<StaleRecordException>()),
      );
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
