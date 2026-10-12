import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/bloc/salary_bloc.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_form.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late DemoController demo;
  late FakeSalaryRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeSalaryRepository(demo: demo);
  });

  SalaryBloc build() {
    return SalaryBloc(
      repository: repository,
      now: () => DateTime(2026, 10, 11),
    );
  }

  const october = YearMonth(2026, 10);
  const september = YearMonth(2026, 9);

  test('starts loading the month of today', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, SalaryStatus.loading);
    expect(bloc.state.month, october);
    expect(bloc.state.canSave, isFalse);
  });

  group('SalaryStarted', () {
    blocTest<SalaryBloc, SalaryState>(
      'shows the saved month with its result',
      build: build,
      act: (bloc) => bloc.add(const SalaryStarted()),
      verify: (bloc) {
        expect(bloc.state.status, SalaryStatus.ready);
        expect(bloc.state.isSaved, isTrue);
        expect(bloc.state.isEdited, isFalse);
        expect(bloc.state.result!.totalAfterTax, rub(104400));
        expect(bloc.state.result!.payments, [rub(104400)]);
        expect(bloc.state.canSave, isTrue);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'shows the two payments when the account is paid twice a month',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: (bloc) => bloc.add(const SalaryStarted()),
      verify: (bloc) {
        expect(bloc.state.result!.payments, [rub(43500), rub(60900)]);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'shows a new, empty month for an account with no data',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const SalaryStarted()),
      verify: (bloc) {
        expect(bloc.state.status, SalaryStatus.ready);
        expect(bloc.state.isSaved, isFalse);
        expect(bloc.state.form.baseSalary, isEmpty);
        expect(bloc.state.form.taxRate, '13');
        expect(bloc.state.result, isNull);
        expect(bloc.state.canSave, isFalse);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const SalaryStarted()),
      verify: (bloc) => expect(bloc.state.status, SalaryStatus.noConnection),
    );

    blocTest<SalaryBloc, SalaryState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const SalaryStarted()),
      verify: (bloc) => expect(bloc.state.status, SalaryStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('SalaryRetried', () {
    blocTest<SalaryBloc, SalaryState>(
      'loads the month again once the server answers',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere(
          (state) => state.status == SalaryStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const SalaryRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, SalaryStatus.ready);
        expect(bloc.state.result!.totalAfterTax, rub(104400));
      },
    );
  });

  group('SalaryFieldChanged', () {
    blocTest<SalaryBloc, SalaryState>(
      'calculates again with what was typed',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryFieldChanged(SalaryField.extraHours, '4'));
      },
      verify: (bloc) {
        expect(bloc.state.isEdited, isTrue);
        expect(bloc.state.result!.totalAfterTax, rub(100050));
      },
    );

    test('does not start the text fields again', () async {
      final bloc = build()..add(const SalaryStarted());
      addTearDown(bloc.close);
      await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
      final version = bloc.state.formVersion;

      bloc.add(const SalaryFieldChanged(SalaryField.extraHours, '5'));
      await bloc.stream.firstWhere((s) => s.form.extraHours == '5');

      expect(bloc.state.formVersion, version);
    });

    blocTest<SalaryBloc, SalaryState>(
      'cannot be saved while a required number is empty',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryFieldChanged(SalaryField.baseSalary, ''));
      },
      verify: (bloc) {
        expect(bloc.state.result, isNull);
        expect(bloc.state.canSave, isFalse);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'cannot be saved while a number is out of range',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryFieldChanged(SalaryField.taxRate, '120'));
      },
      verify: (bloc) {
        expect(bloc.state.calculation, isA<Object>());
        expect(bloc.state.result, isNull);
        expect(bloc.state.canSave, isFalse);
      },
    );
  });

  group('SalaryPaymentModeSelected', () {
    blocTest<SalaryBloc, SalaryState>(
      'splits the month into two payments',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryPaymentModeSelected(PaymentMode.twoPayments));
      },
      verify: (bloc) {
        expect(bloc.state.form.paymentMode, PaymentMode.twoPayments);
        expect(bloc.state.result!.payments, [rub(43500), rub(60900)]);
        expect(bloc.state.isEdited, isTrue);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'does nothing when the month is already paid that way',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryPaymentModeSelected(PaymentMode.onePayment));
      },
      verify: (bloc) => expect(bloc.state.isEdited, isFalse),
    );

    blocTest<SalaryBloc, SalaryState>(
      'cannot be calculated in two payments until the first half is typed',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        for (final (field, value) in [
          (SalaryField.baseSalary, '100000'),
          (SalaryField.workingDaysInMonth, '20'),
          (SalaryField.workingHoursInMonth, '160'),
        ]) {
          bloc.add(SalaryFieldChanged(field, value));
        }
        bloc.add(const SalaryPaymentModeSelected(PaymentMode.twoPayments));
      },
      verify: (bloc) => expect(bloc.state.result, isNull),
    );
  });

  group('SalaryMonthSelected', () {
    blocTest<SalaryBloc, SalaryState>(
      'loads the chosen month',
      build: build,
      act: (bloc) => bloc.add(const SalaryMonthSelected(september)),
      verify: (bloc) {
        expect(bloc.state.month, september);
        expect(bloc.state.isSaved, isTrue);
        expect(bloc.state.result!.totalAfterTax, rub(100050));
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'starts a new month when none was saved',
      build: build,
      act: (bloc) => bloc.add(const SalaryMonthSelected(YearMonth(2026, 11))),
      verify: (bloc) {
        expect(bloc.state.isSaved, isFalse);
        expect(bloc.state.form.baseSalary, isEmpty);
        expect(bloc.state.result, isNull);
      },
    );

    test('starts the text fields again', () async {
      final bloc = build()..add(const SalaryStarted());
      addTearDown(bloc.close);
      await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
      final version = bloc.state.formVersion;

      bloc.add(const SalaryMonthSelected(september));
      await bloc.stream.firstWhere(
        (s) => s.month == september && s.status == SalaryStatus.ready,
      );

      expect(bloc.state.formVersion, greaterThan(version));
    });
  });

  group('SalarySaveRequested', () {
    blocTest<SalaryBloc, SalaryState>(
      'saves, says so, and treats what was typed as the saved month',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc
          ..add(const SalaryFieldChanged(SalaryField.extraHours, '4'))
          ..add(const SalarySaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, SalarySaveStatus.saved);
        expect(bloc.state.isEdited, isFalse);
        expect(bloc.state.isSaved, isTrue);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'passes through saving',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalarySaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, SalarySaveStatus.saved);
      },
      expect: () => [
        isA<SalaryState>().having(
          (s) => s.status,
          'status',
          SalaryStatus.loading,
        ),
        isA<SalaryState>().having(
          (s) => s.status,
          'status',
          SalaryStatus.ready,
        ),
        isA<SalaryState>().having(
          (s) => s.saveStatus,
          'saveStatus',
          SalarySaveStatus.saving,
        ),
        isA<SalaryState>().having(
          (s) => s.saveStatus,
          'saveStatus',
          SalarySaveStatus.saved,
        ),
      ],
    );

    blocTest<SalaryBloc, SalaryState>(
      'a saved correction is what the month shows next time',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc
          ..add(const SalaryFieldChanged(SalaryField.extraHours, '0'))
          ..add(const SalarySaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == SalarySaveStatus.saved,
        );
        bloc.add(const SalaryMonthSelected(september));
        await bloc.stream.firstWhere((s) => s.month == september);
        bloc.add(const SalaryMonthSelected(october));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        // 100,000 + 10,000 food, less 13 % tax.
        expect(bloc.state.result!.totalAfterTax, rub(95700));
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'keeps what was typed when saving fails',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryFieldChanged(SalaryField.extraHours, '4'));
        await bloc.stream.firstWhere((s) => s.form.extraHours == '4');
        demo.update(demo.settings.copyWith(save: DemoSave.fails));
        bloc.add(const SalarySaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, SalarySaveStatus.failed);
        expect(bloc.state.isEdited, isTrue);
        expect(bloc.state.form.extraHours, '4');
        expect(bloc.state.canSave, isTrue);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'can be tried again after it failed',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        demo.update(demo.settings.copyWith(save: DemoSave.fails));
        bloc.add(const SalarySaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == SalarySaveStatus.failed,
        );
        demo.update(demo.settings.copyWith(save: DemoSave.accepted));
        bloc.add(const SalarySaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.saveStatus, SalarySaveStatus.saved),
    );

    test('text typed while a save is sent stays unsaved', () async {
      final slowDemo = DemoController(
        latency: const Duration(milliseconds: 20),
      );
      final bloc = SalaryBloc(
        repository: FakeSalaryRepository(demo: slowDemo),
        now: () => DateTime(2026, 10, 11),
      )..add(const SalaryStarted());
      addTearDown(bloc.close);
      await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);

      bloc.add(const SalarySaveRequested());
      await bloc.stream.firstWhere(
        (s) => s.saveStatus == SalarySaveStatus.saving,
      );
      bloc.add(const SalaryFieldChanged(SalaryField.extraHours, '1'));
      await bloc.stream.firstWhere(
        (s) => s.saveStatus == SalarySaveStatus.saved,
      );

      expect(bloc.state.form.extraHours, '1');
      expect(bloc.state.isEdited, isTrue);
    });

    blocTest<SalaryBloc, SalaryState>(
      'does nothing while the month cannot be calculated',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalarySaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.saveStatus, SalarySaveStatus.idle),
    );

    blocTest<SalaryBloc, SalaryState>(
      'editing after saving goes back to idle',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalarySaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == SalarySaveStatus.saved,
        );
        bloc.add(const SalaryFieldChanged(SalaryField.extraHours, '1'));
      },
      verify: (bloc) => expect(bloc.state.saveStatus, SalarySaveStatus.idle),
    );
  });

  group('the demo panel', () {
    blocTest<SalaryBloc, SalaryState>(
      'switching to an error loads the month again and fails',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, SalaryStatus.failure),
      errors: () => [isA<ServerException>()],
    );

    blocTest<SalaryBloc, SalaryState>(
      'switching to two payments shows the parts',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        demo.update(
          demo.settings.copyWith(paymentMode: PaymentMode.twoPayments),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.result!.payments, hasLength(2));
      },
    );
  });
}
