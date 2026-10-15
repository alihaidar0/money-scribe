import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';
import 'package:money_scribe/features/salary/domain/salary_calculator.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

Money _total(SalaryMonth month) {
  return (SalaryCalculator.calculate(
    month.inputs,
  ) as SalaryComputed).result.totalAfterTax;
}

void main() {
  const october = YearMonth(2026, 10);
  const september = YearMonth(2026, 9);

  late DemoController demo;
  late FakeSalaryRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeSalaryRepository(demo: demo);
  });

  group('the seed', () {
    test('has the months of the design, with their totals', () {
      expect(
        _total(SalarySeed.month(october, PaymentMode.onePayment)!),
        _rub(104400),
      );
      expect(
        _total(SalarySeed.month(september, PaymentMode.onePayment)!),
        _rub(100050),
      );
      expect(
        _total(
          SalarySeed.month(const YearMonth(2026, 8), PaymentMode.onePayment)!,
        ),
        _rub(104400),
      );
    });

    test('has no other month', () {
      expect(
        SalarySeed.month(const YearMonth(2026, 11), PaymentMode.onePayment),
        isNull,
      );
    });

    test('pays the way it is told', () {
      final month = SalarySeed.month(september, PaymentMode.twoPayments)!;
      final result =
          (SalaryCalculator.calculate(month.inputs) as SalaryComputed).result;

      // September's second part is the one of the design.
      expect(result.payments, [_rub(43500), _rub(56550)]);
    });
  });

  group('month', () {
    test('answers with the seed', () async {
      final month = await repository.month(october);

      expect(month, SalarySeed.month(october, PaymentMode.onePayment));
    });

    test('has no saved month when the account is empty', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect(await repository.month(october), isNull);
    });

    test('fails the way the demo panel says', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await expectLater(
        repository.month(october),
        throwsA(isA<NoConnectionException>()),
      );

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await expectLater(
        repository.month(october),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('defaults', () {
    test('follow the payment mode of the demo panel', () async {
      demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));

      expect(
        (await repository.defaults()).paymentMode,
        PaymentMode.twoPayments,
      );
    });
  });

  group('save', () {
    test('keeps the month, replacing the seed', () async {
      final month = SalarySeed.month(october, PaymentMode.onePayment)!;
      final corrected = SalaryMonth(
        month: october,
        inputs: month.inputs,
        firstPayDay: 15,
        secondPayDay: 3,
      );

      await repository.save(corrected);

      expect(await repository.month(october), corrected);
    });

    test('keeps a month even when the account is empty', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));
      final month = SalarySeed.month(october, PaymentMode.onePayment)!;

      await repository.save(month);

      expect(await repository.month(october), month);
      expect(await repository.month(september), isNull);
    });

    test('fails when the demo panel says so, and keeps nothing', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));
      final corrected = SalaryMonth(
        month: october,
        inputs: SalarySeed.month(october, PaymentMode.onePayment)!.inputs,
        firstPayDay: 15,
        secondPayDay: 3,
      );

      await expectLater(
        repository.save(corrected),
        throwsA(isA<NoConnectionException>()),
      );
      expect(
        await repository.month(october),
        SalarySeed.month(october, PaymentMode.onePayment),
      );
    });
  });

  group('savedMonths', () {
    test('lists the seed, the newest first', () async {
      final months = await repository.savedMonths();

      expect(months.map((month) => month.month), SalarySeed.months);
    });

    test('is empty for an empty account', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect(await repository.savedMonths(), isEmpty);
    });

    test('includes what was saved, in its place', () async {
      final older = SalarySeed.month(october, PaymentMode.onePayment)!;
      await repository.save(
        SalaryMonth(
          month: const YearMonth(2026, 1),
          inputs: older.inputs,
          firstPayDay: 20,
          secondPayDay: 5,
        ),
      );

      final months = await repository.savedMonths();

      expect(months.map((month) => month.month), [
        october,
        september,
        const YearMonth(2026, 8),
        const YearMonth(2026, 1),
      ]);
    });

    test('lists a month saved in an empty account', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));
      await repository.save(SalarySeed.month(october, PaymentMode.onePayment)!);

      expect((await repository.savedMonths()).map((m) => m.month), [october]);
    });

    test('fails the way the demo panel says', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await expectLater(
        repository.savedMonths(),
        throwsA(isA<NoConnectionException>()),
      );
    });
  });

  group('delete', () {
    test('removes a seeded month', () async {
      await repository.delete(september);

      expect(await repository.month(september), isNull);
      expect((await repository.savedMonths()).map((month) => month.month), [
        october,
        const YearMonth(2026, 8),
      ]);
    });

    test('removes a month that was saved', () async {
      await repository.save(SalarySeed.month(october, PaymentMode.onePayment)!);
      await repository.delete(october);

      expect(await repository.month(october), isNull);
    });

    test('a month saved again after deleting is back', () async {
      await repository.delete(october);
      final month = SalarySeed.month(october, PaymentMode.onePayment)!;

      await repository.save(month);

      expect(await repository.month(october), month);
    });

    test('deleting a month that is not saved does nothing', () async {
      await repository.delete(const YearMonth(2020, 1));

      expect(await repository.savedMonths(), hasLength(3));
    });

    test('fails when the demo panel says so, and keeps the month', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.delete(october),
        throwsA(isA<NoConnectionException>()),
      );
      expect(await repository.month(october), isNotNull);
    });
  });

  group('changes', () {
    test('emits when the scenario or the payment mode changes', () async {
      final emitted = <void>[];
      final subscription = repository.changes.listen(emitted.add);
      addTearDown(subscription.cancel);

      demo
        ..update(const DemoSettings(scenario: DemoScenario.error))
        ..update(
          const DemoSettings(
            scenario: DemoScenario.error,
            paymentMode: PaymentMode.twoPayments,
          ),
        );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(2));
    });

    test('stays quiet for other settings', () async {
      final emitted = <void>[];
      final subscription = repository.changes.listen(emitted.add);
      addTearDown(subscription.cancel);

      demo.update(const DemoSettings(save: DemoSave.fails));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
    });
  });
}
