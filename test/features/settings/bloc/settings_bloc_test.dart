import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/settings/bloc/settings_bloc.dart';
import 'package:money_scribe/features/settings/data/fake/fake_default_currency_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';

void main() {
  late DemoController demo;
  late FakePayScheduleRepository paySchedule;
  late FakeDefaultCurrencyRepository currency;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    paySchedule = FakePayScheduleRepository(demo: demo);
    currency = FakeDefaultCurrencyRepository(demo: demo);
  });

  SettingsBloc build() {
    return SettingsBloc(paySchedule: paySchedule, currency: currency);
  }

  test('starts loading, with the ruble and one payment', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, SettingsStatus.loading);
    expect(bloc.state.currency, Currency.rub);
    expect(bloc.state.schedule.mode, PaymentMode.onePayment);
  });

  group('SettingsStarted', () {
    blocTest<SettingsBloc, SettingsState>(
      'loads the pay schedule and the currency',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) => bloc.add(const SettingsStarted()),
      verify: (bloc) {
        expect(bloc.state.status, SettingsStatus.ready);
        expect(bloc.state.schedule.mode, PaymentMode.twoPayments);
        expect(bloc.state.currency, Currency.rub);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const SettingsStarted()),
      verify: (bloc) => expect(bloc.state.status, SettingsStatus.noConnection),
    );

    blocTest<SettingsBloc, SettingsState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const SettingsStarted()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, SettingsStatus.failure),
    );

    blocTest<SettingsBloc, SettingsState>(
      'loads again after Try again',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings());
        bloc.add(const SettingsRetried());
      },
      verify: (bloc) => expect(bloc.state.status, SettingsStatus.ready),
    );
  });

  group('SettingsRefreshed', () {
    blocTest<SettingsBloc, SettingsState>(
      'shows what the Pay schedule screen saved, without loading again',
      build: build,
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future<void>.delayed(Duration.zero);
        await paySchedule.save(
          const PaySchedule(
            mode: PaymentMode.twoPayments,
            firstPayDay: 18,
            remindOnPayDays: true,
          ),
        );
        bloc.add(const SettingsRefreshed());
      },
      verify: (bloc) {
        expect(bloc.state.status, SettingsStatus.ready);
        expect(bloc.state.schedule.firstPayDay, 18);
        expect(bloc.state.schedule.remindOnPayDays, isTrue);
      },
    );
  });

  group('DefaultCurrencySelected', () {
    blocTest<SettingsBloc, SettingsState>(
      'shows the currency at once and saves it',
      build: build,
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DefaultCurrencySelected(Currency.eur));
      },
      verify: (bloc) async {
        expect(bloc.state.currency, Currency.eur);
        expect(bloc.state.failedAction, isNull);
        expect(await currency.load(), Currency.eur);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'puts the old currency back when the server does not accept it',
      build: build,
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const DefaultCurrencySelected(Currency.eur));
      },
      verify: (bloc) {
        expect(bloc.state.currency, Currency.rub);
        expect(
          bloc.state.failedAction,
          const DefaultCurrencySelected(Currency.eur),
        );
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'does nothing for the currency that is already the default',
      build: build,
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const DefaultCurrencySelected(Currency.rub));
      },
      verify: (bloc) => expect(bloc.state.failedAction, isNull),
    );
  });

  group('PayDayReminderToggled', () {
    blocTest<SettingsBloc, SettingsState>(
      'turns the reminder on and saves the schedule with it',
      build: build,
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PayDayReminderToggled(remind: true));
      },
      verify: (bloc) {
        expect(bloc.state.schedule.remindOnPayDays, isTrue);
        expect(paySchedule.saved?.remindOnPayDays, isTrue);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'turns it back off when the server does not accept it',
      build: build,
      act: (bloc) async {
        bloc.add(const SettingsStarted());
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
        bloc.add(const PayDayReminderToggled(remind: true));
      },
      verify: (bloc) {
        expect(bloc.state.schedule.remindOnPayDays, isFalse);
        expect(
          bloc.state.failedAction,
          const PayDayReminderToggled(remind: true),
        );
      },
    );
  });
}
