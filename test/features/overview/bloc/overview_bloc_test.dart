import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/overview/bloc/overview_bloc.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late DemoController demo;
  late FakeOverviewRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeOverviewRepository(demo: demo);
  });

  OverviewBloc build() {
    return OverviewBloc(
      repository: repository,
      now: () => DateTime(2026, 10, 11),
    );
  }

  const october = YearMonth(2026, 10);

  test('starts loading the month of today', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, OverviewStatus.loading);
    expect(bloc.state.month, october);
    expect(bloc.state.canStepForward, isFalse);
  });

  group('OverviewStarted', () {
    blocTest<OverviewBloc, OverviewState>(
      'shows the month of today',
      build: build,
      act: (bloc) => bloc.add(const OverviewStarted()),
      verify: (bloc) {
        expect(bloc.state.status, OverviewStatus.ready);
        expect(bloc.state.month, october);
        expect(bloc.state.figures!.balance, rub(60650));
        expect(bloc.state.overview!.hasParts, isFalse);
      },
    );

    blocTest<OverviewBloc, OverviewState>(
      'shows the first launch for an account with no data',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const OverviewStarted()),
      verify: (bloc) {
        expect(bloc.state.status, OverviewStatus.firstLaunch);
        expect(bloc.state.overview, isNull);
      },
    );

    blocTest<OverviewBloc, OverviewState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const OverviewStarted()),
      verify: (bloc) => expect(bloc.state.status, OverviewStatus.noConnection),
    );

    blocTest<OverviewBloc, OverviewState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const OverviewStarted()),
      verify: (bloc) => expect(bloc.state.status, OverviewStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('MonthStepped', () {
    blocTest<OverviewBloc, OverviewState>(
      'goes to the previous month and loads it',
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        bloc.add(const MonthStepped(forward: false));
      },
      verify: (bloc) {
        expect(bloc.state.month, const YearMonth(2026, 9));
        expect(bloc.state.status, OverviewStatus.ready);
        expect(bloc.state.overview!.month, const YearMonth(2026, 9));
        expect(bloc.state.canStepForward, isTrue);
      },
    );

    blocTest<OverviewBloc, OverviewState>(
      'goes forward again, up to the month of today',
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        bloc
          ..add(const MonthStepped(forward: false))
          ..add(const MonthStepped(forward: false));
        await pumpEventQueue();
        bloc.add(const MonthStepped(forward: true));
      },
      verify: (bloc) {
        expect(bloc.state.month, const YearMonth(2026, 9));
        expect(bloc.state.canStepForward, isTrue);
      },
    );

    blocTest<OverviewBloc, OverviewState>(
      'does not go past the month of today',
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        bloc.add(const MonthStepped(forward: true));
      },
      verify: (bloc) {
        expect(bloc.state.month, october);
        expect(bloc.state.canStepForward, isFalse);
      },
    );

    blocTest<OverviewBloc, OverviewState>(
      'shows the loading state while a month loads',
      build: () => OverviewBloc(
        repository: FakeOverviewRepository(
          demo: DemoController(latency: const Duration(milliseconds: 30)),
        ),
        now: () => DateTime(2026, 10, 11),
      ),
      act: (bloc) => bloc.add(const MonthStepped(forward: false)),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<OverviewState>().having(
          (state) => state.status,
          'status',
          OverviewStatus.loading,
        ),
        isA<OverviewState>().having(
          (state) => state.status,
          'status',
          OverviewStatus.ready,
        ),
      ],
    );
  });

  group('PeriodScopeSelected', () {
    blocTest<OverviewBloc, OverviewState>(
      'shows the figures of the chosen part',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        bloc.add(const PeriodScopeSelected(PeriodScope.firstPart));
      },
      verify: (bloc) {
        expect(bloc.state.scope, PeriodScope.firstPart);
        expect(bloc.state.figures!.balance, rub(4750));
      },
    );

    blocTest<OverviewBloc, OverviewState>(
      'back to the month shows the whole month',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        bloc
          ..add(const PeriodScopeSelected(PeriodScope.secondPart))
          ..add(const PeriodScopeSelected(PeriodScope.month));
      },
      verify: (bloc) => expect(bloc.state.figures!.balance, rub(60650)),
    );

    blocTest<OverviewBloc, OverviewState>(
      'keeps the part when the month changes',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        bloc.add(const PeriodScopeSelected(PeriodScope.secondPart));
        await pumpEventQueue();
        bloc.add(const MonthStepped(forward: false));
      },
      verify: (bloc) {
        expect(bloc.state.scope, PeriodScope.secondPart);
        expect(bloc.state.month, const YearMonth(2026, 9));
      },
    );
  });

  group('OverviewRetried', () {
    blocTest<OverviewBloc, OverviewState>(
      'loads again after a failure',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        demo.update(const DemoSettings());
        bloc.add(const OverviewRetried());
      },
      verify: (bloc) => expect(bloc.state.status, OverviewStatus.ready),
    );
  });

  group('when the data changes', () {
    blocTest<OverviewBloc, OverviewState>(
      'loads the month again',
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        demo.update(const DemoSettings(scenario: DemoScenario.empty));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, OverviewStatus.firstLaunch),
    );

    blocTest<OverviewBloc, OverviewState>(
      'shows two parts when the payment mode changes to two',
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.overview!.hasParts, isTrue),
    );

    blocTest<OverviewBloc, OverviewState>(
      'ignores changes of the demo that do not touch the overview',
      build: build,
      act: (bloc) async {
        bloc.add(const OverviewStarted());
        await pumpEventQueue();
        demo
          ..update(const DemoSettings())
          ..update(const DemoSettings(signIn: DemoSignIn.locked));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, OverviewStatus.ready),
    );
  });
}
