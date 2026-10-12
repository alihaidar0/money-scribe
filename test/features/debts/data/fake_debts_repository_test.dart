import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

DebtDraft lee() {
  return DebtDraft(
    direction: DebtDirection.borrowed,
    person: 'Lee',
    amount: rub(1000),
    startDate: DateTime(2026, 10, 10),
  );
}

RepaymentDraft payment(int rubles) {
  return RepaymentDraft(amount: rub(rubles), date: DateTime(2026, 10, 15));
}

void main() {
  late DemoController demo;
  late FakeDebtsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeDebtsRepository(demo: demo);
  });

  group('debts', () {
    test('has the three seeded debts', () async {
      final debts = await repository.debts();

      expect(debts.map((debt) => debt.id), ['sam', 'maria', 'anna']);
    });

    test('has none for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect(await repository.debts(), isEmpty);
    });

    test('reports no connection and a server failure', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await expectLater(
        repository.debts(),
        throwsA(isA<NoConnectionException>()),
      );

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await expectLater(repository.debts(), throwsA(isA<ServerException>()));
    });
  });

  group('debt', () {
    test('finds one by its id', () async {
      expect((await repository.debt('sam'))?.person, 'Sam');
    });

    test('is null for an id that does not exist', () async {
      expect(await repository.debt('missing'), isNull);
    });
  });

  group('add', () {
    test('keeps it after the others, with an id of its own', () async {
      final first = await repository.add(lee());
      final second = await repository.add(lee());

      expect(first.id, isNot(second.id));
      expect(first.repayments, isEmpty);
      expect((await repository.debts()).last, second);
    });

    test('fails when the next save is set to fail', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.add(lee()),
        throwsA(isA<NoConnectionException>()),
      );
      expect(await repository.debts(), hasLength(3));
    });
  });

  group('update', () {
    test('changes the debt and keeps its repayments', () async {
      final saved = await repository.update('sam', lee());

      expect(saved.person, 'Lee');
      expect(saved.repayments, hasLength(1));
      expect((await repository.debt('sam'))?.person, 'Lee');
    });

    test('a debt that is gone is a server failure', () async {
      await expectLater(
        repository.update('missing', lee()),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('delete', () {
    test('removes the debt with its repayments', () async {
      await repository.delete('sam');

      expect(await repository.debt('sam'), isNull);
      expect(await repository.debts(), hasLength(2));
    });

    test('deleting what is gone does nothing', () async {
      await repository.delete('missing');

      expect(await repository.debts(), hasLength(3));
    });
  });

  group('repayments', () {
    test('adding one reduces what is left', () async {
      final debt = await repository.addRepayment('sam', payment(1000));

      expect(debt.repayments, hasLength(2));
      expect(debt.remaining, rub(5000));
      expect((await repository.debt('sam'))?.remaining, rub(5000));
    });

    test('paying the rest settles the debt', () async {
      final debt = await repository.addRepayment('maria', payment(2500));

      expect(debt.isSettled, isTrue);
    });

    test('changing one replaces it in place', () async {
      final debt = await repository.updateRepayment(
        'sam',
        'sam-repayment-1',
        payment(1000),
      );

      expect(debt.repayments.single.id, 'sam-repayment-1');
      expect(debt.repayments.single.amount, rub(1000));
      expect(debt.remaining, rub(9000));
    });

    test('deleting one puts the money back on the debt', () async {
      final debt = await repository.deleteRepayment('sam', 'sam-repayment-1');

      expect(debt.repayments, isEmpty);
      expect(debt.remaining, rub(10000));
    });

    test('a repayment of a debt that is gone is a server failure', () async {
      await expectLater(
        repository.addRepayment('missing', payment(1)),
        throwsA(isA<ServerException>()),
      );
    });

    test('fails when the next save is set to fail', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.addRepayment('sam', payment(1)),
        throwsA(isA<NoConnectionException>()),
      );
      expect((await repository.debt('sam'))?.repayments, hasLength(1));
    });
  });

  test('tells the screens when the demo panel changes the data', () async {
    final changed = expectLater(repository.changes, emits(null));

    demo.update(const DemoSettings(scenario: DemoScenario.empty));

    await changed;
  });
}
