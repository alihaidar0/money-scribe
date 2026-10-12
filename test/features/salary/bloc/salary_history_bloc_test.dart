import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/bloc/salary_history_bloc.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late DemoController demo;
  late FakeSalaryRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeSalaryRepository(demo: demo);
  });

  SalaryHistoryBloc build() {
    return SalaryHistoryBloc(
      repository: repository,
      now: () => DateTime(2026, 10, 11),
    );
  }

  const october = YearMonth(2026, 10);

  test('starts loading, with the month of today as the new month', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, SalaryHistoryStatus.loading);
    expect(bloc.state.newMonth, october);
  });

  group('SalaryHistoryStarted', () {
    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'lists the saved months, the newest first, with what they come to',
      build: build,
      act: (bloc) => bloc.add(const SalaryHistoryStarted()),
      verify: (bloc) {
        final entries = bloc.state.entries;

        expect(bloc.state.status, SalaryHistoryStatus.ready);
        expect(entries.map((entry) => entry.month.month), SalarySeed.months);
        expect(entries.map((entry) => entry.result.totalAfterTax), [
          rub(104400),
          rub(100050),
          rub(104400),
        ]);
        expect(bloc.state.isEmpty, isFalse);
      },
    );

    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'gives each month the payments of its own schedule',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) => bloc.add(const SalaryHistoryStarted()),
      verify: (bloc) {
        expect(
          bloc.state.entries.map((entry) => entry.result.payments.length),
          everyElement(2),
        );
        expect(bloc.state.entries[1].result.payments, [rub(43500), rub(56550)]);
      },
    );

    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'starts a new month before the oldest run of saved months',
      build: build,
      act: (bloc) => bloc.add(const SalaryHistoryStarted()),
      verify: (bloc) {
        // August to October are saved, so the latest free month is July.
        expect(bloc.state.newMonth, const YearMonth(2026, 7));
      },
    );

    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'is empty for an account with no saved month',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const SalaryHistoryStarted()),
      verify: (bloc) {
        expect(bloc.state.status, SalaryHistoryStatus.ready);
        expect(bloc.state.isEmpty, isTrue);
        expect(bloc.state.newMonth, october);
      },
    );

    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const SalaryHistoryStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, SalaryHistoryStatus.noConnection),
    );

    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const SalaryHistoryStarted()),
      verify: (bloc) => expect(bloc.state.status, SalaryHistoryStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('SalaryHistoryRetried', () {
    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'loads the months again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryHistoryStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == SalaryHistoryStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const SalaryHistoryRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, SalaryHistoryStatus.ready);
        expect(bloc.state.entries, hasLength(3));
      },
    );
  });

  group('SalaryHistoryRefreshed', () {
    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'shows what changed without going through loading',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryHistoryStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == SalaryHistoryStatus.ready,
        );
        await repository.delete(october);
        bloc.add(const SalaryHistoryRefreshed());
      },
      expect: () => [
        isA<SalaryHistoryState>().having(
          (s) => s.status,
          'status',
          SalaryHistoryStatus.loading,
        ),
        isA<SalaryHistoryState>().having((s) => s.entries.length, 'entries', 3),
        isA<SalaryHistoryState>()
            .having((s) => s.status, 'status', SalaryHistoryStatus.ready)
            .having((s) => s.entries.length, 'entries', 2),
      ],
      verify: (bloc) {
        // October is gone, so it is the month a new one starts with.
        expect(bloc.state.newMonth, october);
      },
    );
  });

  group('the demo panel', () {
    blocTest<SalaryHistoryBloc, SalaryHistoryState>(
      'switching to an error loads the months again and fails',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryHistoryStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == SalaryHistoryStatus.ready,
        );
        demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, SalaryHistoryStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });
}
