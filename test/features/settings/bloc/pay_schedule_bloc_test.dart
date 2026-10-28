import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/settings/bloc/pay_schedule_bloc.dart';
import 'package:money_scribe/features/settings/data/fake/fake_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';

void main() {
  late DemoController demo;
  late FakePayScheduleRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakePayScheduleRepository(demo: demo);
  });

  PayScheduleBloc build() => PayScheduleBloc(repository: repository);

  test('starts with one payment, paid on day 20 and day 5', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.schedule.mode, PaymentMode.onePayment);
    expect(bloc.state.schedule.firstPayDay, 20);
    expect(bloc.state.schedule.secondPayDay, 5);
  });

  blocTest<PayScheduleBloc, PayScheduleState>(
    'chooses two payments',
    build: build,
    act: (bloc) => bloc.add(const PaymentModeSelected(PaymentMode.twoPayments)),
    expect: () => const [
      PayScheduleState(schedule: PaySchedule(mode: PaymentMode.twoPayments)),
    ],
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'changes the pay days',
    build: build,
    act: (bloc) => bloc
      ..add(const FirstPayDayChanged(18))
      ..add(const SecondPayDayChanged(7)),
    expect: () => const [
      PayScheduleState(schedule: PaySchedule(firstPayDay: 18)),
      PayScheduleState(schedule: PaySchedule(firstPayDay: 18, secondPayDay: 7)),
    ],
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'keeps a pay day inside the month',
    build: build,
    act: (bloc) => bloc
      ..add(const FirstPayDayChanged(40))
      ..add(const SecondPayDayChanged(0)),
    expect: () => const [
      PayScheduleState(schedule: PaySchedule(firstPayDay: 28)),
      PayScheduleState(schedule: PaySchedule(firstPayDay: 28, secondPayDay: 1)),
    ],
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'keeps the second pay day before the first',
    build: build,
    act: (bloc) => bloc
      ..add(const SecondPayDayChanged(25))
      ..add(const FirstPayDayChanged(3)),
    // The second stops one day before the first (20); the first then cannot go
    // to 3, it stays one day after the second (19 + 1), which it already is.
    expect: () => const [
      PayScheduleState(schedule: PaySchedule(secondPayDay: 19)),
    ],
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'moves the first pay day down only as far as the second allows',
    build: build,
    act: (bloc) => bloc.add(const FirstPayDayChanged(2)),
    expect: () => const [
      PayScheduleState(schedule: PaySchedule(firstPayDay: 6)),
    ],
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'saves the schedule when confirmed',
    build: build,
    act: (bloc) => bloc
      ..add(const PaymentModeSelected(PaymentMode.twoPayments))
      ..add(const PayScheduleConfirmed()),
    skip: 1,
    expect: () => const [
      PayScheduleState(
        schedule: PaySchedule(mode: PaymentMode.twoPayments),
        status: PayScheduleStatus.saving,
      ),
      PayScheduleState(
        schedule: PaySchedule(mode: PaymentMode.twoPayments),
        status: PayScheduleStatus.saved,
      ),
    ],
    verify: (_) => expect(
      repository.saved,
      const PaySchedule(mode: PaymentMode.twoPayments),
    ),
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'the saved mode becomes the mode of the fake account',
    build: build,
    act: (bloc) => bloc
      ..add(const PaymentModeSelected(PaymentMode.twoPayments))
      ..add(const PayScheduleConfirmed()),
    verify: (_) => expect(demo.settings.paymentMode, PaymentMode.twoPayments),
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'reports no connection',
    setUp: () =>
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
    build: build,
    act: (bloc) => bloc.add(const PayScheduleConfirmed()),
    expect: () => const [
      PayScheduleState(status: PayScheduleStatus.saving),
      PayScheduleState(status: PayScheduleStatus.noConnection),
    ],
  );

  blocTest<PayScheduleBloc, PayScheduleState>(
    'reports a server failure and the error',
    setUp: () => demo.update(const DemoSettings(scenario: DemoScenario.error)),
    build: build,
    act: (bloc) => bloc.add(const PayScheduleConfirmed()),
    expect: () => const [
      PayScheduleState(status: PayScheduleStatus.saving),
      PayScheduleState(status: PayScheduleStatus.failure),
    ],
    errors: () => [isA<ServerException>()],
  );

  group('PayScheduleStarted', () {
    blocTest<PayScheduleBloc, PayScheduleState>(
      'loads the saved schedule',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) => bloc.add(const PayScheduleStarted()),
      expect: () => const [
        PayScheduleState(status: PayScheduleStatus.loading, isLoaded: false),
        PayScheduleState(schedule: PaySchedule(mode: PaymentMode.twoPayments)),
      ],
    );

    blocTest<PayScheduleBloc, PayScheduleState>(
      'reports no connection, and Try again loads again',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const PayScheduleStarted());
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings());
        bloc.add(const PayScheduleStarted());
      },
      verify: (bloc) {
        expect(bloc.state.status, PayScheduleStatus.editing);
        expect(bloc.state.isLoaded, isTrue);
      },
    );

    blocTest<PayScheduleBloc, PayScheduleState>(
      'a failure to load is not a failure to save',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const PayScheduleStarted()),
      verify: (bloc) {
        expect(bloc.state.status, PayScheduleStatus.noConnection);
        expect(bloc.state.isLoaded, isFalse);
      },
    );

    blocTest<PayScheduleBloc, PayScheduleState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const PayScheduleStarted()),
      errors: () => [isA<ServerException>()],
      verify: (bloc) => expect(bloc.state.status, PayScheduleStatus.failure),
    );
  });

  blocTest<PayScheduleBloc, PayScheduleState>(
    'turns the reminder on and off, and saves it with the schedule',
    build: build,
    act: (bloc) => bloc
      ..add(const RemindOnPayDaysChanged(remind: true))
      ..add(const PayScheduleConfirmed()),
    verify: (_) => expect(repository.saved?.remindOnPayDays, isTrue),
  );
}
