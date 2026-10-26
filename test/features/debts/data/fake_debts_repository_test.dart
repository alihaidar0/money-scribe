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

/// A new person and direction for Sam's debt: its amount and start day stay
/// valid next to the 4,000 already repaid.
DebtDraft samAsLee() {
  return DebtDraft(
    direction: DebtDirection.borrowed,
    person: 'Lee',
    amount: rub(10000),
    startDate: DateTime(2026, 10),
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

    test('refuses a debt past the limit', () async {
      final small = FakeDebtsRepository(demo: demo, maxDebts: 3);

      await expectLater(
        small.add(lee()),
        throwsA(
          isA<DebtRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            DebtRefusal.limitReached,
          ),
        ),
      );
    });

    test('refuses a day outside the years the server keeps', () async {
      final draft = DebtDraft(
        direction: DebtDirection.lent,
        person: 'Lee',
        amount: rub(1000),
        startDate: DateTime(1999, 12, 31),
      );

      await expectLater(
        repository.add(draft),
        throwsA(
          isA<DebtRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            DebtRefusal.dateOutOfRange,
          ),
        ),
      );
    });
  });

  group('update', () {
    test(
      'changes the debt, keeps its repayments, and moves its version',
      () async {
        final saved = await repository.update('sam', samAsLee(), version: 1);

        expect(saved.person, 'Lee');
        expect(saved.repayments, hasLength(1));
        expect(saved.version, 2);
        expect((await repository.debt('sam'))?.person, 'Lee');
      },
    );

    test('keeps the direction, which cannot be changed', () async {
      // `lee()` is a borrowed debt; Sam's was lent.
      final saved = await repository.update('sam', samAsLee(), version: 1);

      expect(saved.direction, DebtDirection.lent);
    });

    test('saving what is already there does not move the version', () async {
      final sam = (await repository.debt('sam'))!;

      final saved = await repository.update('sam', sam.draft, version: 1);

      expect(saved.version, 1);
    });

    test('a version that moved on is stale and changes nothing', () async {
      await repository.update('sam', samAsLee(), version: 1);

      await expectLater(
        repository.update('sam', samAsLee(), version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('a debt that is gone is stale', () async {
      await expectLater(
        repository.update('missing', lee(), version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('the amount cannot go below what was repaid', () async {
      final sam = (await repository.debt('sam'))!;
      final draft = DebtDraft(
        direction: sam.direction,
        person: sam.person,
        amount: rub(3000),
        startDate: sam.startDate,
      );

      await expectLater(
        repository.update('sam', draft, version: 1),
        throwsA(
          isA<DebtRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            DebtRefusal.amountBelowRepaid,
          ),
        ),
      );
    });

    test('the start day cannot go past a repayment', () async {
      final sam = (await repository.debt('sam'))!;
      final draft = DebtDraft(
        direction: sam.direction,
        person: sam.person,
        amount: sam.amount,
        startDate: DateTime(2026, 10, 13),
      );

      await expectLater(
        repository.update('sam', draft, version: 1),
        throwsA(
          isA<DebtRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            DebtRefusal.startAfterRepayment,
          ),
        ),
      );
    });
  });

  group('delete', () {
    test('removes the debt with its repayments', () async {
      await repository.delete('sam', version: 1);

      expect(await repository.debt('sam'), isNull);
      expect(await repository.debts(), hasLength(2));
    });

    test('deleting what is gone does nothing', () async {
      await repository.delete('missing', version: 1);

      expect(await repository.debts(), hasLength(3));
    });

    test('a version that moved on is stale and keeps the debt', () async {
      await expectLater(
        repository.delete('sam', version: 7),
        throwsA(isA<StaleRecordException>()),
      );
      expect(await repository.debt('sam'), isNotNull);
    });
  });

  group('repayments', () {
    test('adding one reduces what is left', () async {
      final debt = await repository.addRepayment('sam', payment(1000));

      expect(debt.repayments, hasLength(2));
      expect(debt.remaining, rub(5000));
      expect((await repository.debt('sam'))?.remaining, rub(5000));
    });

    test('a repayment does not move the version of its debt', () async {
      final debt = await repository.addRepayment('sam', payment(1000));

      expect(debt.version, 1);
    });

    test('they are kept by day', () async {
      final debt = await repository.addRepayment(
        'sam',
        RepaymentDraft(amount: rub(100), date: DateTime(2026, 10, 5)),
      );

      expect(debt.repayments.map((r) => r.id), [
        isNot('sam-repayment-1'),
        'sam-repayment-1',
      ]);
    });

    test('paying the rest settles the debt', () async {
      final debt = await repository.addRepayment('maria', payment(2500));

      expect(debt.isSettled, isTrue);
    });

    test(
      'paying more than what is left is refused with what is left',
      () async {
        await expectLater(
          repository.addRepayment('sam', payment(6001)),
          throwsA(
            isA<DebtRefusedException>()
                .having(
                  (e) => e.refusal,
                  'refusal',
                  DebtRefusal.exceedsRemaining,
                )
                .having((e) => e.remaining, 'remaining', rub(6000)),
          ),
        );
      },
    );

    test('a day before the debt starts is refused', () async {
      await expectLater(
        repository.addRepayment(
          'sam',
          RepaymentDraft(amount: rub(1), date: DateTime(2026, 9, 30)),
        ),
        throwsA(
          isA<DebtRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            DebtRefusal.repaymentBeforeStart,
          ),
        ),
      );
    });

    test('a debt has a limited number of them', () async {
      final small = FakeDebtsRepository(demo: demo, maxRepayments: 1);

      await expectLater(
        small.addRepayment('sam', payment(1)),
        throwsA(
          isA<DebtRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            DebtRefusal.repaymentLimitReached,
          ),
        ),
      );
    });

    test(
      'changing one replaces it in place and moves its own version',
      () async {
        final debt = await repository.updateRepayment(
          'sam',
          'sam-repayment-1',
          payment(1000),
          version: 1,
        );

        expect(debt.repayments.single.id, 'sam-repayment-1');
        expect(debt.repayments.single.amount, rub(1000));
        expect(debt.repayments.single.version, 2);
        expect(debt.version, 1);
        expect(debt.remaining, rub(9000));
      },
    );

    test('a changed repayment can use its own amount again', () async {
      final debt = await repository.updateRepayment(
        'sam',
        'sam-repayment-1',
        payment(10000),
        version: 1,
      );

      expect(debt.isSettled, isTrue);
    });

    test('a repayment version that moved on is stale', () async {
      await expectLater(
        repository.updateRepayment(
          'sam',
          'sam-repayment-1',
          payment(1000),
          version: 9,
        ),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('deleting one puts the money back on the debt', () async {
      final debt = await repository.deleteRepayment(
        'sam',
        'sam-repayment-1',
        version: 1,
      );

      expect(debt.repayments, isEmpty);
      expect(debt.remaining, rub(10000));
    });

    test('deleting a repayment that is gone answers with the debt', () async {
      final debt = await repository.deleteRepayment(
        'sam',
        'missing',
        version: 1,
      );

      expect(debt.id, 'sam');
    });

    test('deleting a repayment at a version that moved on is stale', () async {
      await expectLater(
        repository.deleteRepayment('sam', 'sam-repayment-1', version: 4),
        throwsA(isA<StaleRecordException>()),
      );
    });

    test('a repayment of a debt that is gone is stale', () async {
      await expectLater(
        repository.addRepayment('missing', payment(1)),
        throwsA(isA<StaleRecordException>()),
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

  group('defaultCurrency', () {
    test('is the rouble unless told otherwise', () async {
      expect(await repository.defaultCurrency(), Currency.rub);
    });

    test('is the one the account has', () async {
      final dollars = FakeDebtsRepository(
        demo: demo,
        defaultCurrency: () async => Currency.usd,
      );

      expect(await dollars.defaultCurrency(), Currency.usd);
    });
  });

  test('tells the screens when the demo panel changes the data', () async {
    final changed = expectLater(repository.changes, emits(null));

    demo.update(const DemoSettings(scenario: DemoScenario.empty));

    await changed;
  });
}
