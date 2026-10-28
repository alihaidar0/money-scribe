import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/reports/bloc/reports_bloc.dart';
import 'package:money_scribe/features/reports/data/fake/fake_reports_repository.dart';

import '../../../support/driven_changes_repositories.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  const october = YearMonth(2026, 10);
  const september = YearMonth(2026, 9);

  late DemoController demo;
  late FakeReportsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeReportsRepository(demo: demo);
  });

  ReportsBloc build() {
    return ReportsBloc(
      repository: repository,
      now: () => DateTime(2026, 10, 11),
    );
  }

  test('starts loading the month of today, on the categories', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, ReportsStatus.loading);
    expect(bloc.state.month, october);
    expect(bloc.state.view, ReportsView.categories);
    expect(bloc.state.scope, PeriodScope.month);
  });

  group('ReportsStarted', () {
    blocTest<ReportsBloc, ReportsState>(
      'loads the month, the month before and the debts',
      build: build,
      act: (bloc) => bloc.add(const ReportsStarted()),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.status, ReportsStatus.ready);
        expect(state.period!.spent, rub(52750));
        expect(state.previousPeriod!.spent, rub(55950));
        expect(state.spentChange, rub(-3200));
        expect(state.debts!.owedToYou, rub(8500));
        expect(state.twoPayments, isFalse);
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'is empty for an account with no data',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const ReportsStarted()),
      verify: (bloc) {
        expect(bloc.state.status, ReportsStatus.empty);
        expect(bloc.state.report, isNull);
        // The debts do not depend on the month, so they are still there.
        expect(bloc.state.debts?.isEmpty, isTrue);
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const ReportsStarted()),
      verify: (bloc) => expect(bloc.state.status, ReportsStatus.noConnection),
    );

    blocTest<ReportsBloc, ReportsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const ReportsStarted()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, ReportsStatus.failure),
    );
  });

  group('ReportsRetried', () {
    blocTest<ReportsBloc, ReportsState>(
      'loads again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings());
        bloc.add(const ReportsRetried());
      },
      verify: (bloc) => expect(bloc.state.status, ReportsStatus.ready),
    );
  });

  group('ReportsViewSelected', () {
    blocTest<ReportsBloc, ReportsState>(
      'switches the view and keeps the figures',
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReportsViewSelected(ReportsView.debts));
      },
      verify: (bloc) {
        expect(bloc.state.view, ReportsView.debts);
        expect(bloc.state.status, ReportsStatus.ready);
        expect(bloc.state.debts, isNotNull);
      },
    );
  });

  group('ReportsScopeSelected', () {
    blocTest<ReportsBloc, ReportsState>(
      'shows a part for two payments, and compares the same part',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReportsScopeSelected(PeriodScope.firstPart));
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.twoPayments, isTrue);
        expect(state.effectiveScope, PeriodScope.firstPart);
        expect(state.period!.spent, rub(42750));
        expect(state.previousPeriod!.spent, rub(45300));
        expect(state.spentChange, rub(-2550));
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'is the whole month for one payment, whatever was chosen',
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReportsScopeSelected(PeriodScope.secondPart));
      },
      verify: (bloc) {
        expect(bloc.state.effectiveScope, PeriodScope.month);
        expect(bloc.state.period!.spent, rub(52750));
      },
    );
  });

  group('ReportsMonthSelected', () {
    blocTest<ReportsBloc, ReportsState>(
      'loads the chosen month and the one before it',
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReportsMonthSelected(september));
      },
      verify: (bloc) {
        expect(bloc.state.month, september);
        expect(bloc.state.report!.month, september);
        expect(bloc.state.previousReport!.month, const YearMonth(2026, 8));
        expect(bloc.state.period!.spent, rub(55950));
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'keeps the view and the part that were chosen',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ReportsViewSelected(ReportsView.monthVsMonth))
          ..add(const ReportsScopeSelected(PeriodScope.secondPart))
          ..add(const ReportsMonthSelected(september));
      },
      verify: (bloc) {
        expect(bloc.state.view, ReportsView.monthVsMonth);
        expect(bloc.state.scope, PeriodScope.secondPart);
        expect(bloc.state.month, september);
      },
    );
  });

  group('ReportsCompareMonthSelected', () {
    blocTest<ReportsBloc, ReportsState>(
      'compares with the month before until another is chosen',
      build: build,
      act: (bloc) => bloc.add(const ReportsStarted()),
      verify: (bloc) {
        expect(bloc.state.comparedWith, isNull);
        expect(bloc.state.compareMonth, september);
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'loads the chosen month to compare with',
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReportsCompareMonthSelected(YearMonth(2026, 7)));
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.month, october);
        expect(state.compareMonth, const YearMonth(2026, 7));
        expect(state.previousReport!.month, const YearMonth(2026, 7));
        expect(state.spentChange, rub(-850));
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'choosing another month shows it against the month before it again',
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ReportsCompareMonthSelected(YearMonth(2026, 7)))
          ..add(const ReportsMonthSelected(september));
      },
      verify: (bloc) {
        expect(bloc.state.month, september);
        expect(bloc.state.comparedWith, isNull);
        expect(bloc.state.compareMonth, const YearMonth(2026, 8));
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'keeps the chosen month when the same month is asked for again',
      build: build,
      act: (bloc) async {
        bloc.add(const ReportsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReportsCompareMonthSelected(YearMonth(2026, 7)));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ReportsRetried());
      },
      verify: (bloc) =>
          expect(bloc.state.compareMonth, const YearMonth(2026, 7)),
    );
  });

  test('loads again when the data changes', () async {
    final bloc = build()..add(const ReportsStarted());
    addTearDown(bloc.close);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.twoPayments, isFalse);

    demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.twoPayments, isTrue);
  });

  group('the kind of change', () {
    Future<(ReportsBloc, DrivenChangesReportsRepository)> openShown() async {
      final driven = DrivenChangesReportsRepository(repository);
      final bloc = ReportsBloc(
        repository: driven,
        now: () => DateTime(2026, 10, 11),
      )..add(const ReportsStarted());
      addTearDown(bloc.close);
      await bloc.stream.firstWhere((s) => s.status == ReportsStatus.ready);
      return (bloc, driven);
    }

    test('a saved change reloads without the loading state', () async {
      final (bloc, driven) = await openShown();
      final statuses = <ReportsStatus>[];
      final subscription = bloc.stream.listen(
        (state) => statuses.add(state.status),
      );

      driven.announce(DataChange.saved);
      await pumpEventQueue();
      await subscription.cancel();

      expect(statuses, isNot(contains(ReportsStatus.loading)));
      expect(bloc.state.status, ReportsStatus.ready);
    });

    test('a saved change that fails keeps the report shown', () async {
      final (bloc, driven) = await openShown();
      demo.update(const DemoSettings(scenario: DemoScenario.error));

      driven.announce(DataChange.saved);
      await pumpEventQueue();

      expect(bloc.state.status, ReportsStatus.ready);
      expect(bloc.state.report, isNotNull);
    });

    test('a replaced source starts over with the loading state', () async {
      final (bloc, driven) = await openShown();
      demo.update(const DemoSettings(scenario: DemoScenario.error));
      final statuses = <ReportsStatus>[];
      final subscription = bloc.stream.listen(
        (state) => statuses.add(state.status),
      );

      driven.announce(DataChange.replaced);
      await pumpEventQueue();
      await subscription.cancel();

      expect(statuses.first, ReportsStatus.loading);
      expect(bloc.state.status, ReportsStatus.failure);
    });
  });
}
