import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/bloc/transactions_bloc.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transactions_page.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

void main() {
  late DemoController demo;
  late FakeTransactionsRepository transactions;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    transactions = FakeTransactionsRepository(demo: demo);
  });

  TransactionsBloc build({
    int pageSize = 50,
    Duration searchDelay = Duration.zero,
  }) {
    return TransactionsBloc(
      transactions: transactions,
      accounts: FakeAccountsRepository(demo: demo),
      categories: FakeCategoriesRepository(demo: demo),
      pageSize: pageSize,
      searchDelay: searchDelay,
    );
  }

  /// Waits until [test] is true of the state, now or later.
  Future<void> waitFor(
    TransactionsBloc bloc,
    bool Function(TransactionsState state) test,
  ) async {
    if (test(bloc.state)) return;
    await bloc.stream.firstWhere(test);
  }

  bool resultsReady(TransactionsState s) =>
      s.status == TransactionsStatus.ready &&
      s.resultsStatus == TransactionsResultsStatus.ready &&
      !s.loadingMore;

  /// Starts the Bloc and waits until the transactions are shown.
  Future<void> start(TransactionsBloc bloc) async {
    bloc.add(const TransactionsStarted());
    await waitFor(bloc, resultsReady);
  }

  /// Waits for the results that follow what was just sent: the loading state
  /// first, then the loaded one.
  Future<void> reloaded(TransactionsBloc bloc) async {
    await bloc.stream.firstWhere(
      (s) => s.resultsStatus == TransactionsResultsStatus.loading,
    );
    await waitFor(bloc, resultsReady);
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
      'loads the first page with the totals of its days, the accounts and the '
      'categories',
      build: build,
      act: start,
      verify: (bloc) {
        final state = bloc.state;
        expect(state.transactions.map((t) => t.id), [
          'seed-taxi',
          'seed-coffee',
          'seed-groceries',
          'seed-scholarship',
        ]);
        expect(state.nextCursor, isNull);
        expect(state.dayTotals, {
          DateTime(2026, 10, 19): [const Money(-64000, Currency.rub)],
          DateTime(2026, 10, 17): [const Money(-22000, Currency.rub)],
          DateTime(2026, 10, 5): [const Money(-128450, Currency.rub)],
          DateTime(2026, 10): [const Money(500000, Currency.rub)],
        });
        expect(state.accounts, hasLength(2));
        expect(state.categories, hasLength(8));
        expect(state.twoPayments, isFalse);
        expect(state.hasTransactions, isTrue);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'knows when the salary is paid in two payments',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: start,
      verify: (bloc) => expect(bloc.state.twoPayments, isTrue),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'has no transaction for an account with no data',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: start,
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
      act: (bloc) async {
        bloc.add(const TransactionsStarted());
        await waitFor(bloc, (s) => s.status == TransactionsStatus.noConnection);
      },
      verify: (bloc) =>
          expect(bloc.state.status, TransactionsStatus.noConnection),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) async {
        bloc.add(const TransactionsStarted());
        await waitFor(bloc, (s) => s.status == TransactionsStatus.failure);
      },
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
        await waitFor(bloc, (s) => s.status == TransactionsStatus.noConnection);
        demo.update(const DemoSettings());
        bloc.add(const TransactionsRetried());
        await waitFor(bloc, resultsReady);
      },
      verify: (bloc) {
        expect(bloc.state.status, TransactionsStatus.ready);
        expect(bloc.state.transactions, hasLength(4));
      },
    );

    test('under a failed search only the results load again', () async {
      final flaky = _Flaky(demo: demo);
      final bloc = TransactionsBloc(
        transactions: flaky,
        accounts: FakeAccountsRepository(demo: demo),
        categories: FakeCategoriesRepository(demo: demo),
        searchDelay: Duration.zero,
      );
      addTearDown(bloc.close);
      await start(bloc);

      flaky.failWhen = (filter, cursor) => filter.isSearching;
      bloc.add(const TransactionsSearched('taxi'));
      await waitFor(
        bloc,
        (s) => s.resultsStatus == TransactionsResultsStatus.noConnection,
      );
      // The screen stayed shown, and so did the search.
      expect(bloc.state.status, TransactionsStatus.ready);
      expect(bloc.state.filter.query, 'taxi');

      flaky.failWhen = null;
      bloc.add(const TransactionsRetried());
      await reloaded(bloc);
      expect(bloc.state.status, TransactionsStatus.ready);
      expect(ids(bloc), ['seed-taxi']);
    });
  });

  group('TransactionsRefreshed', () {
    test('shows what changed without going through loading', () async {
      final bloc = build();
      addTearDown(bloc.close);
      await start(bloc);
      await transactions.delete('seed-taxi', version: 1);
      final seen = <TransactionsState>[];
      final subscription = bloc.stream.listen(seen.add);
      addTearDown(subscription.cancel);

      bloc.add(const TransactionsRefreshed());
      await bloc.stream.firstWhere((s) => s.transactions.length == 3);

      expect(
        seen.every(
          (s) =>
              s.status != TransactionsStatus.loading &&
              s.resultsStatus != TransactionsResultsStatus.loading,
        ),
        isTrue,
      );
      expect(bloc.state.transactions, hasLength(3));
    });
  });

  group('paging', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'loads a page, then the next when the end comes into view',
      build: () => build(pageSize: 2),
      act: (bloc) async {
        await start(bloc);
        expect(ids(bloc), ['seed-taxi', 'seed-coffee']);
        expect(bloc.state.nextCursor, isNotNull);

        bloc.add(const TransactionsMoreRequested());
        await waitFor(bloc, (s) => resultsReady(s) && s.nextCursor == null);
      },
      verify: (bloc) {
        expect(ids(bloc), [
          'seed-taxi',
          'seed-coffee',
          'seed-groceries',
          'seed-scholarship',
        ]);
        expect(bloc.state.dayTotals, hasLength(4));
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'reads the totals in step with the list, even a day at a time',
      build: () => build(pageSize: 1),
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.transactions, hasLength(1));
        expect(bloc.state.dayTotals, hasLength(1));

        for (var i = 0; i < 3; i++) {
          bloc.add(const TransactionsMoreRequested());
          await waitFor(
            bloc,
            (s) => resultsReady(s) && s.transactions.length == i + 2,
          );
          // Every loaded day has its total.
          final days = {for (final t in bloc.state.transactions) t.date};
          expect(bloc.state.dayTotals.keys.toSet().containsAll(days), isTrue);
        }
      },
      verify: (bloc) {
        expect(bloc.state.nextCursor, isNull);
        expect(bloc.state.dayTotals, hasLength(4));
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'asks for a page once while it is on its way',
      build: () => build(pageSize: 2),
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionsMoreRequested())
          ..add(const TransactionsMoreRequested())
          ..add(const TransactionsMoreRequested());
        await waitFor(bloc, (s) => resultsReady(s) && s.nextCursor == null);
      },
      verify: (bloc) => expect(bloc.state.transactions, hasLength(4)),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'does nothing at the end of the list',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsMoreRequested());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.loadingMore, isFalse);
        expect(bloc.state.transactions, hasLength(4));
      },
    );

    test(
      'a page that does not load keeps the list and can be asked again',
      () async {
        final flaky = _Flaky(demo: demo);
        final bloc = TransactionsBloc(
          transactions: flaky,
          accounts: FakeAccountsRepository(demo: demo),
          categories: FakeCategoriesRepository(demo: demo),
          pageSize: 2,
          searchDelay: Duration.zero,
        );
        addTearDown(bloc.close);
        await start(bloc);

        flaky.failWhen = (filter, cursor) => cursor != null;
        bloc.add(const TransactionsMoreRequested());
        await waitFor(bloc, (s) => s.loadMoreFailed);
        expect(bloc.state.transactions, hasLength(2));
        expect(bloc.state.loadingMore, isFalse);

        flaky.failWhen = null;
        bloc.add(const TransactionsMoreRetried());
        await waitFor(bloc, (s) => resultsReady(s) && s.nextCursor == null);
        expect(bloc.state.loadMoreFailed, isFalse);
        expect(bloc.state.transactions, hasLength(4));
      },
    );
  });

  group('TransactionsSearched', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'asks the server for the notes with the words',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('coffee'));
        await reloaded(bloc);
      },
      verify: (bloc) {
        expect(ids(bloc), ['seed-coffee']);
        expect(bloc.state.isNarrowed, isTrue);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'shows no totals of the days while a search is on',
      build: build,
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.shownDayTotals, isNotEmpty);
        bloc.add(const TransactionsSearched('coffee'));
        await reloaded(bloc);
      },
      verify: (bloc) {
        expect(bloc.state.shownDayTotals, isNull);
        expect(bloc.state.dayTotals, isEmpty);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'the totals come back when the search is cleared',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('coffee'));
        await reloaded(bloc);
        bloc.add(const TransactionsSearched(''));
        await reloaded(bloc);
      },
      verify: (bloc) {
        expect(bloc.state.shownDayTotals, hasLength(4));
        expect(ids(bloc), hasLength(4));
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'looks in the note only, not in the category or the account',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('cash'));
        await reloaded(bloc);
      },
      verify: (bloc) => expect(ids(bloc), isEmpty),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'one letter is not a search: nothing is asked',
      build: build,
      act: (bloc) async {
        await start(bloc);
        final seen = <TransactionsState>[];
        final subscription = bloc.stream.listen(seen.add);
        bloc.add(const TransactionsSearched('c'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await subscription.cancel();
        expect(
          seen.any((s) => s.resultsStatus == TransactionsResultsStatus.loading),
          isFalse,
        );
      },
      verify: (bloc) {
        expect(bloc.state.filter.query, 'c');
        expect(ids(bloc), hasLength(4));
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'waits for the person to stop typing before it asks',
      build: () => build(searchDelay: const Duration(milliseconds: 60)),
      act: (bloc) async {
        await start(bloc);
        final loads = <TransactionsState>[];
        final subscription = bloc.stream
            .where((s) => s.resultsStatus == TransactionsResultsStatus.loading)
            .listen(loads.add);

        bloc.add(const TransactionsSearched('ta'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const TransactionsSearched('tax'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const TransactionsSearched('taxi'));
        // Not yet: the last key was 20 ms ago.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(loads, isEmpty);
        expect(ids(bloc), hasLength(4));

        await waitFor(
          bloc,
          (s) => resultsReady(s) && s.transactions.length == 1,
        );
        await subscription.cancel();
        // One question for three keys.
        expect(loads, hasLength(1));
      },
      verify: (bloc) {
        expect(bloc.state.filter.query, 'taxi');
        expect(ids(bloc), ['seed-taxi']);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'no match leaves nothing',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('xyz'));
        await reloaded(bloc);
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
        bloc.add(const TransactionsSearched('ta'));
        await reloaded(bloc);
        bloc.add(
          const TransactionFiltersApplied(
            TransactionFilter(categoryIds: {'transport'}),
            PeriodScope.month,
          ),
        );
        await reloaded(bloc);
      },
      verify: (bloc) {
        expect(bloc.state.filter.query, 'ta');
        expect(ids(bloc), ['seed-taxi']);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'narrows by account and by day, and the totals follow',
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
        await reloaded(bloc);
      },
      verify: (bloc) {
        expect(ids(bloc), ['seed-groceries']);
        expect(bloc.state.dayTotals.keys, [DateTime(2026, 10, 5)]);
      },
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
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(ids(bloc), ['seed-taxi', 'seed-coffee']);
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
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.effectiveScope, PeriodScope.month);
        expect(bloc.state.visible, hasLength(4));
      },
    );
  });

  group('a screen opened with a filter already chosen', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'is shown with the filtered results, whichever load finishes last',
      build: build,
      act: (bloc) async {
        // As when the Reports send the person to one category.
        bloc
          ..add(const TransactionsStarted())
          ..add(
            const TransactionFiltersApplied(
              TransactionFilter(categoryIds: {'groceries'}),
              PeriodScope.month,
            ),
          );
        await waitFor(bloc, resultsReady);
      },
      verify: (bloc) {
        expect(bloc.state.status, TransactionsStatus.ready);
        expect(ids(bloc), ['seed-groceries']);
        expect(bloc.state.accounts, hasLength(2));
        // Something narrowed the list, so it is not known to be empty.
        expect(bloc.state.hasTransactions, isTrue);
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'a failure before the screen is shown is the failure of the screen',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc
          ..add(const TransactionsStarted())
          ..add(
            const TransactionFiltersApplied(
              TransactionFilter(categoryIds: {'groceries'}),
              PeriodScope.month,
            ),
          );
        await waitFor(bloc, (s) => s.status == TransactionsStatus.noConnection);
      },
      verify: (bloc) =>
          expect(bloc.state.status, TransactionsStatus.noConnection),
    );
  });

  group('TransactionsScopeSelected', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'shows one part of the month from the pages that are loaded',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        final seen = <TransactionsState>[];
        final subscription = bloc.stream.listen(seen.add);
        bloc.add(const TransactionsScopeSelected(PeriodScope.firstPart));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await subscription.cancel();
        // Nothing was asked of the server.
        expect(
          seen.any((s) => s.resultsStatus == TransactionsResultsStatus.loading),
          isFalse,
        );
      },
      verify: (bloc) =>
          expect(ids(bloc), ['seed-groceries', 'seed-scholarship']),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'loads more pages when the part shows too little of the first one',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      // Two a page: the first page holds the two days of the second part.
      build: () => build(pageSize: 2),
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.transactions, hasLength(2));

        bloc.add(const TransactionsScopeSelected(PeriodScope.firstPart));
        await waitFor(bloc, (s) => resultsReady(s) && s.visible.length == 2);
      },
      verify: (bloc) {
        expect(ids(bloc), ['seed-groceries', 'seed-scholarship']);
        expect(bloc.state.transactions, hasLength(4));
      },
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
        bloc.add(const TransactionsSearched('xyz'));
        await reloaded(bloc);
        bloc.add(const TransactionFiltersCleared());
        await reloaded(bloc);
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
        await waitFor(bloc, (s) => s.twoPayments);
      },
      verify: (bloc) => expect(bloc.state.twoPayments, isTrue),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'switching to an error fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
        await waitFor(bloc, (s) => s.status == TransactionsStatus.failure);
      },
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
        await Future<void>.delayed(Duration.zero);
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
        await waitFor(
          bloc,
          (s) => resultsReady(s) && s.transactions.length == 1,
        );
      },
      verify: (bloc) => expect(bloc.state.selected?.id, 'seed-taxi'),
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'shows nothing when no transaction passes the filters',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionsSearched('no such thing'));
        await reloaded(bloc);
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
        await waitFor(bloc, (s) => s.transactions.length == 3);
      },
      verify: (bloc) {
        expect(bloc.state.transactions, hasLength(3));
        expect(bloc.state.deleteStatus, TransactionsDeleteStatus.idle);
        expect(bloc.state.selected?.id, 'seed-coffee');
        // The total of the deleted day is gone with it.
        expect(
          bloc.state.dayTotals.keys,
          isNot(contains(DateTime(2026, 10, 19))),
        );
      },
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'a transaction changed on another device is not deleted',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await transactions.update(
          'seed-taxi',
          TransactionDraft(
            amount: const Money(70000, Currency.rub),
            kind: TransactionKind.expense,
            date: DateTime(2026, 10, 19),
            categoryId: 'transport',
            accountId: 'card',
            note: 'Taxi',
          ),
          version: 1,
        );
        bloc.add(const TransactionDeleteConfirmed('seed-taxi'));
        await waitFor(
          bloc,
          (s) =>
              s.deleteStatus == TransactionsDeleteStatus.stale &&
              resultsReady(s) &&
              s.transactions.first.version == 2,
        );
      },
      verify: (bloc) {
        expect(bloc.state.transactions, hasLength(4));
        expect(bloc.state.transactions.first.version, 2);
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
        await waitFor(
          bloc,
          (s) => s.deleteStatus == TransactionsDeleteStatus.failed,
        );
      },
      verify: (bloc) {
        expect(bloc.state.deleteStatus, TransactionsDeleteStatus.failed);
        expect(bloc.state.deletingId, 'seed-taxi');
      },
    );
  });
}

/// Transactions that fail the requests [failWhen] picks, as a connection lost
/// in the middle of scrolling or of a search would.
class _Flaky extends FakeTransactionsRepository {
  new({required super.demo});

  bool Function(TransactionFilter filter, String? cursor)? failWhen;

  @override
  Future<TransactionsPage> transactions(
    TransactionFilter filter, {
    String? cursor,
    int pageSize = TransactionsRepository.defaultPageSize,
  }) {
    if (failWhen?.call(filter, cursor) ?? false) {
      throw const NoConnectionException();
    }
    return super.transactions(filter, cursor: cursor, pageSize: pageSize);
  }
}
