import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/transactions/bloc/accounts_bloc.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';

void main() {
  late DemoController demo;
  late FakeTransactionsRepository transactions;
  late FakeAccountsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    transactions = FakeTransactionsRepository(demo: demo);
    repository = FakeAccountsRepository(demo: demo, transactions: transactions);
  });

  AccountsBloc build() => AccountsBloc(repository: repository);

  const draft = AccountDraft(name: 'Savings', kind: AccountKind.other);

  Future<void> start(AccountsBloc bloc) async {
    bloc.add(const AccountsStarted());
    await Future<void>.delayed(Duration.zero);
  }

  group('AccountsStarted', () {
    blocTest<AccountsBloc, AccountsState>(
      'loads the card and cash',
      build: build,
      act: (bloc) => bloc.add(const AccountsStarted()),
      verify: (bloc) {
        expect(bloc.state.status, AccountsStatus.ready);
        expect(bloc.state.accounts.map((a) => a.name), ['Card', 'Cash']);
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const AccountsStarted()),
      verify: (bloc) => expect(bloc.state.status, AccountsStatus.noConnection),
    );

    blocTest<AccountsBloc, AccountsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const AccountsStarted()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, AccountsStatus.failure),
    );
  });

  group('AccountAdded', () {
    blocTest<AccountsBloc, AccountsState>(
      'adds the account at the end of the list',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const AccountAdded(draft));
      },
      verify: (bloc) {
        expect(bloc.state.accounts.last.name, 'Savings');
        expect(bloc.state.accounts.last.kind, AccountKind.other);
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'keeps the list and the action when the server does not accept it',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const AccountAdded(draft));
      },
      verify: (bloc) {
        expect(bloc.state.accounts, hasLength(2));
        expect(bloc.state.failedAction, const AccountAdded(draft));
      },
    );
  });

  group('AccountChanged', () {
    blocTest<AccountsBloc, AccountsState>(
      'renames the account in place',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const AccountChanged('cash', draft));
      },
      verify: (bloc) {
        expect(bloc.state.accounts.map((a) => a.name), ['Card', 'Savings']);
      },
    );
  });

  group('AccountDeleted', () {
    blocTest<AccountsBloc, AccountsState>(
      'deletes an account that has no transactions',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const AccountAdded(draft));
        await Future<void>.delayed(Duration.zero);
        bloc.add(AccountDeleted(bloc.state.accounts.last.id));
      },
      verify: (bloc) {
        expect(bloc.state.accounts.map((a) => a.name), ['Card', 'Cash']);
        expect(bloc.state.deleteBlocked, isFalse);
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'refuses to delete an account that has transactions',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const AccountDeleted('card'));
      },
      verify: (bloc) {
        expect(bloc.state.accounts, hasLength(2));
        expect(bloc.state.deleteBlocked, isTrue);
        expect(bloc.state.failedAction, isNull);
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'forgets the refusal when something else is done',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const AccountDeleted('card'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountAdded(draft));
      },
      verify: (bloc) => expect(bloc.state.deleteBlocked, isFalse),
    );
  });

  group('a change made on another device', () {
    blocTest<AccountsBloc, AccountsState>(
      'loads the list again and keeps the action to apply once more',
      build: build,
      act: (bloc) async {
        await start(bloc);
        // Another device renames the account first.
        await repository.update(
          'cash',
          const AccountDraft(name: 'Wallet', kind: AccountKind.cash),
          version: 1,
        );
        bloc.add(
          const AccountChanged(
            'cash',
            AccountDraft(name: 'Pocket', kind: AccountKind.cash),
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.staleAction, isA<AccountChanged>());
        expect(bloc.state.failedAction, isNull);
        // The list is what is on the server now.
        expect(bloc.state.accounts.map((a) => a.name), ['Card', 'Wallet']);
        expect(bloc.state.accounts.last.version, 2);
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'applying the action again changes the account at its new version',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await repository.update(
          'cash',
          const AccountDraft(name: 'Wallet', kind: AccountKind.cash),
          version: 1,
        );
        const change = AccountChanged(
          'cash',
          AccountDraft(name: 'Pocket', kind: AccountKind.cash),
        );
        bloc.add(change);
        await Future<void>.delayed(Duration.zero);
        bloc.add(change);
      },
      verify: (bloc) {
        expect(bloc.state.staleAction, isNull);
        expect(bloc.state.accounts.last.name, 'Pocket');
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'deleting an account that changed is not done',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await repository.update(
          'cash',
          const AccountDraft(name: 'Wallet', kind: AccountKind.cash),
          version: 1,
        );
        bloc.add(const AccountDeleted('cash'));
      },
      verify: (bloc) {
        expect(bloc.state.staleAction, isA<AccountDeleted>());
        expect(bloc.state.accounts, hasLength(2));
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'an account deleted elsewhere is a stale change, not a failure',
      build: build,
      act: (bloc) async {
        final added = await repository.add(draft);
        await start(bloc);
        await repository.delete(added.id, version: added.version);
        bloc.add(
          AccountChanged(
            added.id,
            const AccountDraft(name: 'Pocket', kind: AccountKind.cash),
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.staleAction, isA<AccountChanged>());
        expect(bloc.state.accounts.map((a) => a.id), ['card', 'cash']);
      },
    );
  });

  group('a refusal the person can act on', () {
    blocTest<AccountsBloc, AccountsState>(
      'a name that is taken is reported, not retried',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(
          const AccountAdded(
            AccountDraft(name: 'cash', kind: AccountKind.cash),
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.refusal, AccountRefusal.nameTaken);
        expect(bloc.state.failedAction, isNull);
        expect(bloc.state.accounts, hasLength(2));
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'the next action clears the refusal',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(
          const AccountAdded(
            AccountDraft(name: 'cash', kind: AccountKind.cash),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountAdded(draft));
      },
      verify: (bloc) {
        expect(bloc.state.refusal, isNull);
        expect(bloc.state.accounts.last.name, 'Savings');
      },
    );
  });
}
