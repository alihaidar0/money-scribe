import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/bloc/transactions_bloc.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';

void main() {
  late DemoController demo;
  late FakeTransactionsRepository transactions;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    transactions = FakeTransactionsRepository(demo: demo);
  });

  TransactionsBloc build() {
    return TransactionsBloc(
      transactions: transactions,
      accounts: FakeAccountsRepository(demo: demo),
      categories: FakeCategoriesRepository(demo: demo),
    );
  }

  /// Starts the Bloc and waits until the transactions are shown.
  Future<void> start(TransactionsBloc bloc) async {
    bloc.add(const TransactionsStarted());
    await bloc.stream.firstWhere((s) => s.status == TransactionsStatus.ready);
  }

  List<String> ids(TransactionsBloc bloc) =>
      bloc.state.visible.map((item) => item.id).toList();

  test('starts loading', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, TransactionsStatus.loading);
  });

  group('TransactionsStarted', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'loads the transactions with the accounts and the categories',
      build: build,
      act: (bloc) => bloc.add(const TransactionsStarted()),
      expect: () => [
        isA<TransactionsState>().having(
          (s) => s.status,
          'status',
          TransactionsStatus.loading,
        ),
        isA<TransactionsState>()
            .having((s) => s.status, 'status', TransactionsStatus.ready)
            .having((s) => s.transactions.length, 'transactions', 4)
            .having((s) => s.accounts.length, 'accounts', 2)
            .having((s) => s.categories.length, 'categories', 8)
            .having((s) => s.twoPayments, 'twoPayments', isFalse),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'knows when the salary is paid in two payments',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) => bloc.add(const TransactionsStarted()),
      verify: (bloc) => expect(bloc.state.twoPayments, isTrue),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'has no transaction for an account with no data',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const TransactionsStarted()),
      verify: (bloc) {
        expect(bloc.state.status, TransactionsStatus.ready);
        expect(bloc.state.hasTransactions, isFalse);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const TransactionsStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, TransactionsStatus.noConnection),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const TransactionsStarted()),
      verify: (bloc) => expect(bloc.state.status, TransactionsStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('TransactionsRetried', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'loads again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const TransactionsStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == TransactionsStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const TransactionsRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, TransactionsStatus.ready);
        expect(bloc.state.transactions, hasLength(4));
      },
    );
  });

  group('TransactionsRefreshed', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'shows what changed without going through loading',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await transactions.delete('seed-taxi');
        bloc.add(const TransactionsRefreshed());
      },
      expect: () => [
        isA<TransactionsState>().having(
          (s) => s.status,
          'status',
          TransactionsStatus.loading,
        ),
        isA<TransactionsState>().having(
          (s) => s.transactions.length,
          'transactions',
          4,
        ),
        isA<TransactionsState>()
            .having((s) => s.status, 'status', TransactionsStatus.ready)
            .having((s) => s.transactions.length, 'transactions', 3),
      ],
    );
  });

  group('TransactionsSearched', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'narrows the list to what matches the words',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('coffee'));
      },
      verify: (bloc) {
        expect(ids(bloc), ['seed-coffee']);
        expect(bloc.state.isNarrowed, isTrue);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'finds by the name of the category and of the account',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('cash'));
      },
      verify: (bloc) => expect(ids(bloc), ['seed-coffee']),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'no match leaves nothing',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('xyz'));
      },
      verify: (bloc) {
        expect(bloc.state.visible, isEmpty);
        expect(bloc.state.hasTransactions, isTrue);
      },
    );
  });

  group('TransactionFiltersApplied', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'narrows by category and keeps the search words',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionsSearched('o'))
          ..add(
            const TransactionFiltersApplied(
              TransactionFilter(categoryIds: {'transport'}),
              PeriodScope.month,
            ),
          );
      },
      verify: (bloc) {
        expect(bloc.state.filter.query, 'o');
        expect(ids(bloc), ['seed-taxi']);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'narrows by account and by day',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(
          TransactionFiltersApplied(
            TransactionFilter(
              accountIds: const {'card'},
              from: DateTime(2026, 10, 5),
              to: DateTime(2026, 10, 18),
            ),
            PeriodScope.month,
          ),
        );
      },
      verify: (bloc) => expect(ids(bloc), ['seed-groceries']),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'a part shows the days of that part of the month, for two payments',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(
          const TransactionFiltersApplied(
            TransactionFilter(),
            PeriodScope.secondPart,
          ),
        );
      },
      verify: (bloc) {
        expect(ids(bloc), ['seed-coffee', 'seed-taxi']);
        expect(bloc.state.isNarrowed, isTrue);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'a part is ignored for one payment',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(
          const TransactionFiltersApplied(
            TransactionFilter(),
            PeriodScope.secondPart,
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.effectiveScope, PeriodScope.month);
        expect(bloc.state.visible, hasLength(4));
      },
    );
  });

  group('TransactionsScopeSelected', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'shows one part of the month',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsScopeSelected(PeriodScope.firstPart));
      },
      verify: (bloc) =>
          expect(ids(bloc), ['seed-scholarship', 'seed-groceries']),
    );
  });

  group('TransactionFiltersCleared', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'clears the search, the filters and the part',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionsSearched('xyz'))
          ..add(const TransactionsScopeSelected(PeriodScope.firstPart))
          ..add(const TransactionFiltersCleared());
      },
      verify: (bloc) {
        expect(bloc.state.filter.isActive, isFalse);
        expect(bloc.state.scope, PeriodScope.month);
        expect(bloc.state.visible, hasLength(4));
        expect(bloc.state.isNarrowed, isFalse);
      },
    );
  });

  group('the demo panel', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'switching to two payments loads again and splits the list',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(
          demo.settings.copyWith(paymentMode: PaymentMode.twoPayments),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.twoPayments, isTrue),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'switching to an error fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, TransactionsStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('TransactionSelected', () {
    test('the newest transaction is shown until one is chosen', () async {
      final bloc = build();
      addTearDown(bloc.close);
      await start(bloc);

      expect(bloc.state.selectedId, isNull);
      expect(bloc.state.selected?.id, 'seed-taxi');
    });

    blocTest<TransactionsBloc, TransactionsState>(
      'shows the chosen transaction',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionSelected('seed-groceries'));
      },
      verify: (bloc) => expect(bloc.state.selected?.id, 'seed-groceries'),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'falls back to the newest one when the chosen one is filtered out',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionSelected('seed-groceries'))
          ..add(const TransactionsSearched('taxi'));
      },
      verify: (bloc) => expect(bloc.state.selected?.id, 'seed-taxi'),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'shows nothing when no transaction passes the filters',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('no such thing'));
      },
      verify: (bloc) => expect(bloc.state.selected, isNull),
    );
  });

  group('TransactionDeleteConfirmed', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'deletes the transaction and shows the rest',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionDeleteConfirmed('seed-taxi'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.transactions, hasLength(3));
        expect(bloc.state.deleteStatus, TransactionsDeleteStatus.idle);
        expect(bloc.state.selected?.id, 'seed-coffee');
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'reports no connection and keeps the transaction',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(
          demo.settings.copyWith(scenario: DemoScenario.noConnection),
        );
        bloc.add(const TransactionDeleteConfirmed('seed-taxi'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.deleteStatus, TransactionsDeleteStatus.failed);
        expect(bloc.state.deletingId, 'seed-taxi');
        expect(bloc.state.status, TransactionsStatus.noConnection);
      },
    );
  });
}
