import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/bloc/debts_bloc.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late DemoController demo;
  late FakeDebtsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeDebtsRepository(demo: demo);
  });

  DebtsBloc build() {
    return DebtsBloc(
      repository: repository,
      now: () => DateTime(2026, 10, 11, 18),
    );
  }

  /// Starts the Bloc and waits until the debts are shown.
  Future<void> start(DebtsBloc bloc) async {
    bloc.add(const DebtsStarted());
    await bloc.stream.firstWhere((s) => s.status == DebtsStatus.ready);
  }

  test('starts loading, knowing the day of today', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, DebtsStatus.loading);
    expect(bloc.state.today, DateTime(2026, 10, 11));
  });

  group('DebtsStarted', () {
    blocTest<DebtsBloc, DebtsState>(
      'loads the debts, those still to be repaid first',
      build: build,
      act: (bloc) => bloc.add(const DebtsStarted()),
      expect: () => [
        isA<DebtsState>().having(
          (s) => s.status,
          'status',
          DebtsStatus.loading,
        ),
        isA<DebtsState>()
            .having((s) => s.status, 'status', DebtsStatus.ready)
            .having((s) => s.debts.length, 'debts', 3),
      ],
      verify: (bloc) {
        expect(bloc.state.shown.map((debt) => debt.id), [
          'sam',
          'maria',
          'anna',
        ]);
      },
    );

    blocTest<DebtsBloc, DebtsState>(
      'adds up what is owed to the person and what they owe',
      build: build,
      act: start,
      verify: (bloc) {
        expect(bloc.state.owedToYou, rub(8500));
        expect(bloc.state.youOwe, rub(0));
      },
    );

    blocTest<DebtsBloc, DebtsState>(
      'has no debt for an account with no data',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: start,
      verify: (bloc) {
        expect(bloc.state.debts, isEmpty);
        expect(bloc.state.owedToYou, rub(0));
      },
    );

    blocTest<DebtsBloc, DebtsState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const DebtsStarted()),
      verify: (bloc) => expect(bloc.state.status, DebtsStatus.noConnection),
    );

    blocTest<DebtsBloc, DebtsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const DebtsStarted()),
      verify: (bloc) => expect(bloc.state.status, DebtsStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('DebtsRetried', () {
    blocTest<DebtsBloc, DebtsState>(
      'loads again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const DebtsStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == DebtsStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const DebtsRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, DebtsStatus.ready);
        expect(bloc.state.debts, hasLength(3));
      },
    );
  });

  group('DebtsFilterSelected', () {
    blocTest<DebtsBloc, DebtsState>(
      'Lent lists the debts lent',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtsFilterSelected(DebtsFilter.lent));
      },
      verify: (bloc) {
        expect(bloc.state.shown.map((debt) => debt.id), ['sam', 'maria']);
      },
    );

    blocTest<DebtsBloc, DebtsState>(
      'Borrowed lists the debts borrowed',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtsFilterSelected(DebtsFilter.borrowed));
      },
      verify: (bloc) {
        expect(bloc.state.shown.map((debt) => debt.id), ['anna']);
      },
    );

    blocTest<DebtsBloc, DebtsState>(
      'the sums do not depend on the filter',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtsFilterSelected(DebtsFilter.borrowed));
      },
      verify: (bloc) => expect(bloc.state.owedToYou, rub(8500)),
    );

    blocTest<DebtsBloc, DebtsState>(
      'a settled debt goes last',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await repository.addRepayment(
          'sam',
          RepaymentDraft(amount: rub(6000), date: DateTime(2026, 10, 12)),
        );
        bloc.add(const DebtsRefreshed());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.shown.map((debt) => debt.id), [
          'maria',
          'sam',
          'anna',
        ]);
      },
    );
  });

  group('DebtsRefreshed', () {
    blocTest<DebtsBloc, DebtsState>(
      'shows what changed without going through loading',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await repository.delete('maria');
        bloc.add(const DebtsRefreshed());
      },
      expect: () => [
        isA<DebtsState>().having(
          (s) => s.status,
          'status',
          DebtsStatus.loading,
        ),
        isA<DebtsState>().having((s) => s.debts.length, 'debts', 3),
        isA<DebtsState>()
            .having((s) => s.status, 'status', DebtsStatus.ready)
            .having((s) => s.debts.length, 'debts', 2),
      ],
    );
  });

  group('the demo panel', () {
    blocTest<DebtsBloc, DebtsState>(
      'switching to an error loads again and fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, DebtsStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('DebtSelected', () {
    test('the first debt of the list is shown until one is chosen', () async {
      final bloc = build();
      addTearDown(bloc.close);
      await start(bloc);

      expect(bloc.state.selectedId, isNull);
      expect(bloc.state.selected?.id, 'sam');
    });

    blocTest<DebtsBloc, DebtsState>(
      'shows the chosen debt',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtSelected('anna'));
      },
      verify: (bloc) => expect(bloc.state.selected?.id, 'anna'),
    );

    blocTest<DebtsBloc, DebtsState>(
      'falls back to the first one when the chosen one is filtered out',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const DebtSelected('anna'))
          ..add(const DebtsFilterSelected(DebtsFilter.lent));
      },
      verify: (bloc) => expect(bloc.state.selected?.id, 'sam'),
    );
  });

  group('DebtDeleteConfirmed', () {
    blocTest<DebtsBloc, DebtsState>(
      'deletes the debt and shows the rest',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtDeleteConfirmed('sam'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.debts.map((debt) => debt.id), ['maria', 'anna']);
        expect(bloc.state.deleteStatus, DebtsDeleteStatus.idle);
        expect(bloc.state.selected?.id, 'maria');
      },
    );

    blocTest<DebtsBloc, DebtsState>(
      'reports no connection and keeps the debt',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(
          demo.settings.copyWith(scenario: DemoScenario.noConnection),
        );
        bloc.add(const DebtDeleteConfirmed('sam'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.deleteStatus, DebtsDeleteStatus.failed);
        expect(bloc.state.deletingId, 'sam');
      },
    );
  });
}
