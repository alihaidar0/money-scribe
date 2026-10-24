import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/salary/bloc/salary_compare_bloc.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';
import 'package:money_scribe/features/salary/domain/salary_comparison.dart';

void main() {
  late DemoController demo;
  late FakeSalaryRepository repository;
  late FakeFixedItemsRepository fixedItems;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeSalaryRepository(demo: demo);
    fixedItems = FakeFixedItemsRepository(demo: demo);
  });

  SalaryCompareBloc build() {
    return SalaryCompareBloc(
      repository: repository,
      fixedItems: fixedItems,
      now: () => DateTime(2026, 10, 11),
    );
  }

  /// Starts the Bloc and waits until the months are shown.
  Future<void> start(SalaryCompareBloc bloc) async {
    bloc.add(const SalaryCompareStarted());
    await bloc.stream.firstWhere((s) => s.status == SalaryCompareStatus.ready);
  }

  const july = YearMonth(2026, 7);
  const august = YearMonth(2026, 8);
  const september = YearMonth(2026, 9);
  const october = YearMonth(2026, 10);

  test('starts loading, comparing the month before today with today', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, SalaryCompareStatus.loading);
    expect(bloc.state.left, september);
    expect(bloc.state.right, october);
  });

  group('SalaryCompareStarted', () {
    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'compares the two newest saved months, the earlier on the left',
      build: build,
      act: (bloc) => bloc.add(const SalaryCompareStarted()),
      expect: () => [
        isA<SalaryCompareState>().having(
          (s) => s.status,
          'status',
          SalaryCompareStatus.loading,
        ),
        isA<SalaryCompareState>()
            .having((s) => s.status, 'status', SalaryCompareStatus.ready)
            .having((s) => s.saved.length, 'saved', 3)
            .having((s) => s.left, 'left', september)
            .having((s) => s.right, 'right', october),
      ],
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'has the figures of both months ready to compare',
      build: build,
      act: (bloc) => bloc.add(const SalaryCompareStarted()),
      verify: (bloc) {
        final lines = bloc.state.lines;

        expect(lines.map((line) => line.kind), [
          ComparisonLineKind.incomeBeforeTax,
          ComparisonLineKind.tax,
          ComparisonLineKind.totalAfterTax,
        ]);
        expect(lines.last.difference?.minorUnits, 435000);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'with one saved month compares it with the month before',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) async {
        await repository.save(
          SalarySeed.month(august, PaymentMode.onePayment)!.withVersion(null),
        );
        bloc.add(const SalaryCompareStarted());
      },
      verify: (bloc) {
        expect(bloc.state.status, SalaryCompareStatus.ready);
        expect(bloc.state.left, july);
        expect(bloc.state.right, august);
        expect(bloc.state.leftEntry, isNull);
        expect(bloc.state.rightEntry, isNotNull);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'with no saved month compares the month before today with today',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const SalaryCompareStarted()),
      verify: (bloc) {
        expect(bloc.state.status, SalaryCompareStatus.ready);
        expect(bloc.state.left, september);
        expect(bloc.state.right, october);
        expect(bloc.state.lines.map((line) => line.difference), [
          null,
          null,
          null,
        ]);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const SalaryCompareStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, SalaryCompareStatus.noConnection),
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const SalaryCompareStarted()),
      verify: (bloc) => expect(bloc.state.status, SalaryCompareStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('SalaryCompareRetried', () {
    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'loads the months again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryCompareStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == SalaryCompareStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const SalaryCompareRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, SalaryCompareStatus.ready);
        // The months are picked now, as they were not before.
        expect(bloc.state.left, september);
        expect(bloc.state.right, october);
      },
    );
  });

  group('SalaryCompareMonthChosen', () {
    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'changes the month of the side that was chosen',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SalaryCompareMonthChosen(CompareSide.left, august));
      },
      verify: (bloc) {
        expect(bloc.state.left, august);
        expect(bloc.state.right, october);
        expect(bloc.state.lines.last.difference?.minorUnits, 0);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'a month with no saved salary has no figures',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SalaryCompareMonthChosen(CompareSide.right, july));
      },
      verify: (bloc) {
        expect(bloc.state.right, july);
        expect(bloc.state.rightEntry, isNull);
        expect(bloc.state.lines.map((line) => line.right), [null, null, null]);
        expect(bloc.state.lines.map((line) => line.difference), [
          null,
          null,
          null,
        ]);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'is kept when the months are loaded again',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const SalaryCompareMonthChosen(CompareSide.left, august))
          ..add(const SalaryCompareDataChanged());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, SalaryCompareStatus.ready);
        expect(bloc.state.left, august);
        expect(bloc.state.right, october);
      },
    );
  });

  group('the fixed items', () {
    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'are loaded for the two months that are compared',
      build: build,
      act: (bloc) => bloc.add(const SalaryCompareStarted()),
      verify: (bloc) {
        expect(
          bloc.state.fixedItems.keys,
          unorderedEquals([september, october]),
        );
        expect(bloc.state.fixedItems[october], hasLength(3));
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'are loaded for a month that is chosen',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SalaryCompareMonthChosen(CompareSide.left, august));
      },
      verify: (bloc) {
        expect(bloc.state.fixedItems.containsKey(august), isTrue);
        expect(bloc.state.fixedItems[august], hasLength(3));
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'are not asked for a month with no saved salary',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SalaryCompareMonthChosen(CompareSide.left, july));
      },
      verify: (bloc) {
        expect(bloc.state.fixedItems.containsKey(july), isFalse);
        expect(bloc.state.status, SalaryCompareStatus.ready);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'are not loaded again for a month that has them',
      build: build,
      act: (bloc) async {
        await start(bloc);
        final item = bloc.state.fixedItems[october]!.first;
        await fixedItems.delete(october, item.id, version: item.version);
        bloc.add(const SalaryCompareMonthChosen(CompareSide.left, october));
      },
      verify: (bloc) {
        // Still the three loaded at the start.
        expect(bloc.state.fixedItems[october], hasLength(3));
      },
    );
  });

  group('SalaryCompareSwapped', () {
    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'puts each month on the other side and turns the difference around',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SalaryCompareSwapped());
      },
      verify: (bloc) {
        expect(bloc.state.left, october);
        expect(bloc.state.right, september);
        expect(bloc.state.lines.last.difference?.minorUnits, -435000);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'twice is back to the start',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const SalaryCompareSwapped())
          ..add(const SalaryCompareSwapped());
      },
      verify: (bloc) {
        expect(bloc.state.left, september);
        expect(bloc.state.right, october);
      },
    );
  });

  group('SalaryCompareScopeSelected', () {
    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'compares one part of months paid in two payments, fixed items too',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SalaryCompareScopeSelected(PeriodScope.secondPart));
      },
      verify: (bloc) {
        expect(bloc.state.hasParts, isTrue);
        expect(bloc.state.effectiveScope, PeriodScope.secondPart);
        expect(bloc.state.lines.map((line) => line.kind), [
          ComparisonLineKind.payAfterTax,
          ComparisonLineKind.fixedItems,
          ComparisonLineKind.balanceAfterFixedItems,
        ]);
        expect(bloc.state.lines.first.difference?.minorUnits, 435000);
        expect(bloc.state.lines.last.right?.minorUnits, 6590000);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'shows the whole month while no month is paid in two payments',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const SalaryCompareScopeSelected(PeriodScope.secondPart));
      },
      verify: (bloc) {
        expect(bloc.state.hasParts, isFalse);
        expect(bloc.state.scope, PeriodScope.secondPart);
        expect(bloc.state.effectiveScope, PeriodScope.month);
        expect(bloc.state.lines, hasLength(3));
      },
    );
  });

  group('the demo panel', () {
    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'switching to two payments loads the months again and offers the parts',
      build: build,
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.hasParts, isFalse);
        demo.update(
          demo.settings.copyWith(paymentMode: PaymentMode.twoPayments),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, SalaryCompareStatus.ready);
        expect(bloc.state.hasParts, isTrue);
      },
    );

    blocTest<SalaryCompareBloc, SalaryCompareState>(
      'switching to an error fails',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, SalaryCompareStatus.failure),
      // The salary and the fixed items both announce the change, so the screen
      // loads, and fails, twice.
      errors: () => [isA<ServerException>(), isA<ServerException>()],
    );
  });
}
