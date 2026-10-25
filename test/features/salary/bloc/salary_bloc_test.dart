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
import 'package:money_scribe/features/salary/domain/salary_result.dart';

import '../../../support/fake_server_salary_repository.dart';

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
      'starts a new month when none was saved, with the figures of the last',
      build: build,
      act: (bloc) => bloc.add(const SalaryMonthSelected(YearMonth(2025, 10))),
      verify: (bloc) {
        expect(bloc.state.month, const YearMonth(2025, 10));
        expect(bloc.state.isSaved, isFalse);
        expect(bloc.state.version, 0);
        expect(bloc.state.form.baseSalary, '100000.00');
        expect(bloc.state.form.foodPerDay, '500.00');
        expect(bloc.state.form.workingHoursInMonth, '160');
        // What changes every month is left for the person to type.
        expect(bloc.state.form.workingDaysInMonth, isEmpty);
        expect(bloc.state.form.extraHours, isEmpty);
        expect(bloc.state.result, isNull);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'ignores a month after the month of today',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryMonthSelected(YearMonth(2026, 11)));
      },
      verify: (bloc) {
        expect(bloc.state.month, october);
        expect(bloc.state.status, SalaryStatus.ready);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'accepts the month of today',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryMonthSelected(september));
        await bloc.stream.firstWhere((s) => s.month == september);
        bloc.add(const SalaryMonthSelected(october));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.month, october),
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

  group('a month changed on another device', () {
    blocTest<SalaryBloc, SalaryState>(
      'is not replaced by a save, and keeps what was typed',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        // Another device saves the month first.
        await repository.save((await repository.month(october))!);
        bloc
          ..add(const SalaryFieldChanged(SalaryField.extraHours, '4'))
          ..add(const SalarySaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, SalarySaveStatus.stale);
        expect(bloc.state.form.extraHours, '4');
        expect(bloc.state.isEdited, isTrue);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'is loaded again on request',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        await repository.save((await repository.month(october))!);
        bloc
          ..add(const SalaryFieldChanged(SalaryField.extraHours, '4'))
          ..add(const SalarySaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == SalarySaveStatus.stale,
        );
        bloc.add(const SalaryRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.version, 2);
        expect(bloc.state.isEdited, isFalse);
        expect(bloc.state.saveStatus, SalarySaveStatus.idle);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'is not deleted, and stays saved',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        await repository.save((await repository.month(october))!);
        bloc.add(const SalaryDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.deleteStatus, SalaryDeleteStatus.stale);
        expect(bloc.state.isSaved, isTrue);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'can be saved twice in a row: the second save follows the first',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc
          ..add(const SalaryFieldChanged(SalaryField.extraHours, '4'))
          ..add(const SalarySaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == SalarySaveStatus.saved,
        );
        bloc
          ..add(const SalaryFieldChanged(SalaryField.extraHours, '5'))
          ..add(const SalarySaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, SalarySaveStatus.saved);
        expect(bloc.state.version, 3);
      },
    );
  });

  group('SalaryStarted with a month', () {
    blocTest<SalaryBloc, SalaryState>(
      'loads that month instead of the month of today',
      build: build,
      act: (bloc) => bloc.add(const SalaryStarted(month: september)),
      verify: (bloc) {
        expect(bloc.state.month, september);
        expect(bloc.state.isSaved, isTrue);
        expect(bloc.state.result!.totalAfterTax, rub(100050));
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'starts an empty month for one that was not saved in an empty account',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) => bloc.add(const SalaryStarted(month: YearMonth(2025, 1))),
      verify: (bloc) {
        expect(bloc.state.month, const YearMonth(2025, 1));
        expect(bloc.state.isSaved, isFalse);
        expect(bloc.state.form.baseSalary, isEmpty);
      },
    );
  });

  group('SalaryDeleteRequested', () {
    blocTest<SalaryBloc, SalaryState>(
      'deletes the saved month',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.deleteStatus, SalaryDeleteStatus.deleted);
        expect(await repository.month(october), isNull);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'passes through deleting',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      skip: 2,
      expect: () => [
        isA<SalaryState>().having(
          (s) => s.deleteStatus,
          'deleteStatus',
          SalaryDeleteStatus.deleting,
        ),
        isA<SalaryState>().having(
          (s) => s.deleteStatus,
          'deleteStatus',
          SalaryDeleteStatus.deleted,
        ),
      ],
    );

    blocTest<SalaryBloc, SalaryState>(
      'keeps the month when deleting fails',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        demo.update(demo.settings.copyWith(save: DemoSave.fails));
        bloc.add(const SalaryDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.deleteStatus, SalaryDeleteStatus.failed);
        expect(bloc.state.isSaved, isTrue);
        expect(await repository.month(october), isNotNull);
      },
    );

    blocTest<SalaryBloc, SalaryState>(
      'can be tried again after it failed',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        demo.update(demo.settings.copyWith(save: DemoSave.fails));
        bloc.add(const SalaryDeleteRequested());
        await bloc.stream.firstWhere(
          (s) => s.deleteStatus == SalaryDeleteStatus.failed,
        );
        demo.update(demo.settings.copyWith(save: DemoSave.accepted));
        bloc.add(const SalaryDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) =>
          expect(bloc.state.deleteStatus, SalaryDeleteStatus.deleted),
    );

    blocTest<SalaryBloc, SalaryState>(
      'does nothing for a month that was not saved',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.empty)),
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) =>
          expect(bloc.state.deleteStatus, SalaryDeleteStatus.idle),
    );

    blocTest<SalaryBloc, SalaryState>(
      'loading another month forgets a finished deletion',
      build: build,
      act: (bloc) async {
        bloc.add(const SalaryStarted());
        await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
        bloc.add(const SalaryDeleteRequested());
        await bloc.stream.firstWhere(
          (s) => s.deleteStatus == SalaryDeleteStatus.deleted,
        );
        bloc.add(const SalaryMonthSelected(september));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) =>
          expect(bloc.state.deleteStatus, SalaryDeleteStatus.idle),
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

  group('the figures the server calculated', () {
    late FakeServerSalaryRepository server;

    setUp(() {
      // The server's food allowance is a ruble more than the app's, so the
      // two can be told apart on screen.
      server = FakeServerSalaryRepository(repository)
        ..resultOf = (result) => SalaryResult(
          foodAllowance: result.foodAllowance + rub(1),
          extraHoursPay: result.extraHoursPay,
          incomeBeforeTax: result.incomeBeforeTax,
          tax: result.tax,
          totalAfterTax: result.totalAfterTax,
          payments: result.payments,
        );
    });

    SalaryBloc buildFromServer() {
      return SalaryBloc(repository: server, now: () => DateTime(2026, 10, 11));
    }

    Future<void> ready(SalaryBloc bloc) async {
      bloc.add(const SalaryStarted());
      await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);
    }

    test('a saved month shows the lines the server calculated', () async {
      final bloc = buildFromServer();
      addTearDown(bloc.close);

      await ready(bloc);

      expect(bloc.state.figures, isNotNull);
      expect(bloc.state.result!.foodAllowance, rub(10000));
      expect(bloc.state.shownResult!.foodAllowance, rub(10001));
      expect(bloc.state.shownResult, bloc.state.figures!.result);
      expect(bloc.state.savedTotalAfterTax, isNull);
    });

    test('an edit shows the live calculation, with the saved total', () async {
      final bloc = buildFromServer();
      addTearDown(bloc.close);
      await ready(bloc);

      bloc.add(const SalaryFieldChanged(SalaryField.extraHours, '5'));
      await bloc.stream.firstWhere((s) => s.isEdited);

      expect(bloc.state.shownResult, bloc.state.result);
      expect(bloc.state.shownResult!.foodAllowance, rub(10000));
      expect(bloc.state.savedTotalAfterTax, rub(104400));
    });

    test(
      'saving shows the lines the server calculated for what it saved',
      () async {
        final bloc = buildFromServer();
        addTearDown(bloc.close);
        await ready(bloc);
        bloc.add(const SalaryFieldChanged(SalaryField.extraHours, '5'));
        await bloc.stream.firstWhere((s) => s.isEdited);

        bloc.add(const SalarySaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == SalarySaveStatus.saved,
        );

        expect(bloc.state.isEdited, isFalse);
        expect(bloc.state.figures!.result.foodAllowance, rub(10001));
        expect(bloc.state.shownResult, bloc.state.figures!.result);
        // The extra hours of the saved month are the ones that were typed.
        expect(bloc.state.shownResult!.extraHoursPay, isNot(rub(10000)));
        expect(bloc.state.savedTotalAfterTax, isNull);
      },
    );

    test('a month that is not saved has no figures to show', () async {
      final bloc = buildFromServer();
      addTearDown(bloc.close);

      bloc.add(const SalaryStarted(month: YearMonth(2026, 3)));
      await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);

      expect(bloc.state.isSaved, isFalse);
      expect(bloc.state.figures, isNull);
      expect(bloc.state.shownResult, bloc.state.result);
      expect(bloc.state.savedTotalAfterTax, isNull);
    });

    test('loading another month drops the figures of the one before', () async {
      final bloc = buildFromServer();
      addTearDown(bloc.close);
      await ready(bloc);
      expect(bloc.state.figures, isNotNull);

      bloc.add(const SalaryMonthSelected(YearMonth(2026, 3)));
      await bloc.stream.firstWhere(
        (s) =>
            s.month == const YearMonth(2026, 3) &&
            s.status == SalaryStatus.ready,
      );

      expect(bloc.state.figures, isNull);
    });

    test("data that is not the server's is calculated here", () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const SalaryStarted());
      await bloc.stream.firstWhere((s) => s.status == SalaryStatus.ready);

      expect(bloc.state.figures, isNull);
      expect(bloc.state.shownResult, bloc.state.result);
    });
  });
}
