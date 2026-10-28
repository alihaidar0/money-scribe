import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/reports/data/fake/fake_reports_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';

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

  group('month', () {
    test(
      'has the spending of October by category, the biggest first',
      () async {
        final report = (await repository.month(october))!;
        final names = [
          for (final category in report.total.categories) category.name,
        ];
        final amounts = [
          for (final category in report.total.categories) category.amount,
        ];

        expect(names, [
          'Housing',
          'Groceries',
          'Utilities',
          'Transport',
          'Dining',
          'Other',
        ]);
        expect(amounts, [
          rub(30000),
          rub(9800),
          rub(4500),
          rub(3400),
          rub(3150),
          rub(1900),
        ]);
        expect(report.total.spent, rub(52750));
        expect(report.total.income, rub(109400));
        expect(report.hasParts, isFalse);
      },
    );

    test('has September to compare with', () async {
      final report = (await repository.month(september))!;

      expect(report.total.spent, rub(55950));
      expect(report.total.income, rub(105050));
    });

    test(
      'has both parts for two payments, and they add up to the month',
      () async {
        demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));

        final report = (await repository.month(october))!;

        expect(report.hasParts, isTrue);
        expect(report.firstPart!.spent, rub(42750));
        expect(report.firstPart!.income, rub(43500));
        expect(
          report.firstPart!.spent + report.secondPart!.spent,
          report.total.spent,
        );
        expect(
          report.firstPart!.income + report.secondPart!.income,
          report.total.income,
        );
        // A category with nothing spent in a part is left out of it.
        expect(
          report.secondPart!.categories.map((category) => category.name),
          isNot(contains('Housing')),
        );
      },
    );

    test('September part 1 is what the comparison of parts shows', () async {
      demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));

      final report = (await repository.month(september))!;

      expect(report.firstPart!.spent, rub(45300));
    });

    test('is null for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect(await repository.month(october), isNull);
    });

    test(
      'a month saved with two payments has its parts, the others not',
      () async {
        final salary = FakeSalaryRepository(demo: demo);
        final saved = SalarySeed.month(september, PaymentMode.twoPayments)!;

        await salary.save(saved);

        expect((await repository.month(september))!.hasParts, isTrue);
        expect((await repository.month(october))!.hasParts, isFalse);
      },
    );

    test('deleting that month goes back to the account schedule', () async {
      final salary = FakeSalaryRepository(demo: demo);
      await salary.save(SalarySeed.month(september, PaymentMode.twoPayments)!);

      await salary.delete(september, version: 2);

      expect((await repository.month(september))!.hasParts, isFalse);
    });

    test(
      'tells the screens when a month is saved with another schedule',
      () async {
        final salary = FakeSalaryRepository(demo: demo);
        var count = 0;
        final subscription = repository.changes.listen((_) => count++);
        addTearDown(subscription.cancel);

        await salary.save(
          SalarySeed.month(september, PaymentMode.twoPayments)!,
        );
        await Future<void>.delayed(Duration.zero);

        expect(count, 1);
      },
    );

    test('fails like the server does', () async {
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

  group('debts', () {
    test('has what is owed, the overdue debts and the open ones', () async {
      final report = await repository.debts();

      expect(report.owedToYou, rub(8500));
      expect(report.youOwe, rub(0));
      expect(report.overdue.single.person, 'Maria');
      expect(report.overdue.single.status, DebtStatus.overdue);
      expect(report.open.single.person, 'Sam');
    });

    test('is empty for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      final report = await repository.debts();

      expect(report.isEmpty, isTrue);
      expect(report.owedToYou, rub(0));
    });
  });

  test('tells when the data changes', () async {
    final changes = <DataChange>[];
    final subscription = repository.changes.listen(changes.add);
    addTearDown(subscription.cancel);

    demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments));
    await Future<void>.delayed(Duration.zero);

    expect(changes, [DataChange.replaced]);
  });
}
