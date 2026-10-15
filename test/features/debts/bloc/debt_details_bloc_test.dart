import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/bloc/debt_details_bloc.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

RepaymentDraft payment(int rubles) {
  return RepaymentDraft(amount: rub(rubles), date: DateTime(2026, 10, 15));
}

void main() {
  late DemoController demo;
  late FakeDebtsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeDebtsRepository(demo: demo);
  });

  DebtDetailsBloc build({String id = 'sam'}) {
    return DebtDetailsBloc(
      repository: repository,
      id: id,
      now: () => DateTime(2026, 10, 11),
    );
  }

  /// Starts the Bloc and waits until the debt is shown.
  Future<void> start(DebtDetailsBloc bloc) async {
    bloc.add(const DebtDetailsStarted());
    await bloc.stream.firstWhere((s) => s.status == DebtDetailsStatus.ready);
  }

  test('starts loading the debt it was given', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, DebtDetailsStatus.loading);
    expect(bloc.state.debtId, 'sam');
  });

  group('DebtDetailsStarted', () {
    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'loads the debt',
      build: build,
      act: (bloc) => bloc.add(const DebtDetailsStarted()),
      expect: () => [
        isA<DebtDetailsState>().having(
          (s) => s.status,
          'status',
          DebtDetailsStatus.loading,
        ),
        isA<DebtDetailsState>()
            .having((s) => s.status, 'status', DebtDetailsStatus.ready)
            .having((s) => s.debt?.person, 'person', 'Sam')
            .having((s) => s.debt?.remaining, 'remaining', rub(6000)),
      ],
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'a debt that does not exist is not found',
      build: () => build(id: 'missing'),
      act: (bloc) => bloc.add(const DebtDetailsStarted()),
      verify: (bloc) => expect(bloc.state.status, DebtDetailsStatus.notFound),
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const DebtDetailsStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, DebtDetailsStatus.noConnection),
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const DebtDetailsStarted()),
      verify: (bloc) => expect(bloc.state.status, DebtDetailsStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('DebtDetailsRetried', () {
    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'loads again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const DebtDetailsStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == DebtDetailsStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const DebtDetailsRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, DebtDetailsStatus.ready),
    );
  });

  group('RepaymentAdded', () {
    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'adds the repayment and reduces what is left',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(RepaymentAdded(payment(1500)));
      },
      verify: (bloc) {
        expect(bloc.state.debt?.repayments, hasLength(2));
        expect(bloc.state.debt?.remaining, rub(4500));
        expect(bloc.state.failedAction, isNull);
      },
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'paying the rest settles the debt',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(RepaymentAdded(payment(6000)));
      },
      verify: (bloc) => expect(bloc.state.debt?.isSettled, isTrue),
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'keeps the debt and remembers the action when saving fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(RepaymentAdded(payment(1500)));
      },
      verify: (bloc) {
        expect(bloc.state.debt?.repayments, hasLength(1));
        expect(bloc.state.failedAction, RepaymentAdded(payment(1500)));
      },
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'trying again once the server accepts it adds the repayment',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(RepaymentAdded(payment(1500)));
        await bloc.stream.firstWhere((s) => s.failedAction != null);
        demo.update(const DemoSettings());
        bloc.add(bloc.state.failedAction!);
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.debt?.repayments, hasLength(2));
        expect(bloc.state.failedAction, isNull);
      },
    );
  });

  group('RepaymentChanged', () {
    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'replaces the repayment',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(RepaymentChanged('sam-repayment-1', payment(1000)));
      },
      verify: (bloc) {
        expect(bloc.state.debt?.repayments.single.amount, rub(1000));
        expect(bloc.state.debt?.remaining, rub(9000));
      },
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'keeps the repayment when saving fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(RepaymentChanged('sam-repayment-1', payment(1000)));
      },
      verify: (bloc) {
        expect(bloc.state.debt?.repayments.single.amount, rub(4000));
        expect(bloc.state.failedAction, isA<RepaymentChanged>());
      },
    );
  });

  group('RepaymentDeleted', () {
    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'removes the repayment and puts the money back on the debt',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const RepaymentDeleted('sam-repayment-1'));
      },
      verify: (bloc) {
        expect(bloc.state.debt?.repayments, isEmpty);
        expect(bloc.state.debt?.remaining, rub(10000));
      },
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'keeps the repayment when deleting fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const RepaymentDeleted('sam-repayment-1'));
      },
      verify: (bloc) {
        expect(bloc.state.debt?.repayments, hasLength(1));
        expect(bloc.state.failedAction, isA<RepaymentDeleted>());
      },
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'the next action clears the failure',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const RepaymentDeleted('sam-repayment-1'));
        await bloc.stream.firstWhere((s) => s.failedAction != null);
        demo.update(const DemoSettings());
        bloc.add(RepaymentAdded(payment(100)));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.failedAction, isNull),
    );
  });

  group('DebtDeleteRequested', () {
    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'deletes the debt',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.deleteStatus, DebtDeleteStatus.deleted);
        expect(await repository.debt('sam'), isNull);
      },
    );

    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'a failed delete leaves the debt',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const DebtDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.deleteStatus, DebtDeleteStatus.failed);
        expect(await repository.debt('sam'), isNotNull);
      },
    );
  });

  group('DebtDetailsRefreshed', () {
    blocTest<DebtDetailsBloc, DebtDetailsState>(
      'shows what changed without going through loading',
      build: build,
      act: (bloc) async {
        await start(bloc);
        await repository.deleteRepayment('sam', 'sam-repayment-1');
        bloc.add(const DebtDetailsRefreshed());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.debt?.remaining, rub(10000)),
    );
  });
}
