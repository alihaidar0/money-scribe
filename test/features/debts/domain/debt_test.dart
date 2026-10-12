import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/data/fake/debts_seed.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

final today = DateTime(2026, 10, 11);

void main() {
  final debts = {for (final debt in DebtsSeed.debts()) debt.id: debt};
  final sam = debts['sam']!;
  final maria = debts['maria']!;
  final anna = debts['anna']!;

  group('Debt', () {
    test('adds up what was repaid and what is left', () {
      expect(sam.repaid, rub(4000));
      expect(sam.remaining, rub(6000));
      expect(maria.repaid, rub(0));
      expect(maria.remaining, rub(2500));
    });

    test('is settled when everything was repaid', () {
      expect(anna.isSettled, isTrue);
      expect(anna.remaining, rub(0));
      expect(sam.isSettled, isFalse);
    });

    test('what is left is never below nothing', () {
      final over = sam.withRepayments([
        Repayment(id: 'x', amount: rub(12000), date: DateTime(2026, 10, 12)),
      ]);

      expect(over.remaining, rub(0));
      expect(over.isSettled, isTrue);
    });

    test('progress is the share repaid, from 0 to 1', () {
      expect(sam.progress, closeTo(0.4, 1e-9));
      expect(maria.progress, 0);
      expect(anna.progress, 1);
    });

    group('statusOn', () {
      test('is open before the due day', () {
        expect(sam.statusOn(today), DebtStatus.open);
      });

      test('is open on the due day itself', () {
        expect(sam.statusOn(DateTime(2026, 10, 31)), DebtStatus.open);
      });

      test('is overdue the day after the due day', () {
        expect(sam.statusOn(DateTime(2026, 11)), DebtStatus.overdue);
        expect(maria.statusOn(today), DebtStatus.overdue);
      });

      test('is settled once repaid, even past the due day', () {
        expect(anna.statusOn(today), DebtStatus.settled);
        final late = maria.withRepayments([
          Repayment(id: 'x', amount: rub(2500), date: today),
        ]);
        expect(late.statusOn(DateTime(2027)), DebtStatus.settled);
      });

      test('is open with no due day, however late', () {
        final open = Debt(
          id: 'x',
          direction: DebtDirection.lent,
          person: 'Lee',
          amount: rub(100),
          startDate: DateTime(2020),
        );

        expect(open.statusOn(DateTime(2030)), DebtStatus.open);
      });

      test('ignores the time of day', () {
        expect(sam.statusOn(DateTime(2026, 10, 31, 23, 59)), DebtStatus.open);
      });
    });

    test('its draft is what it is made of', () {
      expect(sam.draft.person, 'Sam');
      expect(sam.draft.dueDate, DateTime(2026, 10, 31));
    });

    test('a draft changes it and keeps its repayments', () {
      final changed = sam.withDraft(
        DebtDraft(
          direction: DebtDirection.borrowed,
          person: 'Samuel',
          amount: rub(9000),
          startDate: DateTime(2026, 10, 2),
          note: 'x',
        ),
      );

      expect(changed.id, 'sam');
      expect(changed.person, 'Samuel');
      expect(changed.direction, DebtDirection.borrowed);
      expect(changed.dueDate, isNull);
      expect(changed.repayments, sam.repayments);
    });
  });

  group('DebtDraft.tryCreate', () {
    DebtDraft? create({
      String person = 'Sam',
      String amount = '10000',
      DateTime? start,
      DateTime? due,
      String note = '',
    }) {
      return DebtDraft.tryCreate(
        direction: DebtDirection.lent,
        person: person,
        amount: amount,
        currency: Currency.rub,
        startDate: start ?? DateTime(2026, 10, 1, 9, 30),
        dueDate: due,
        note: note,
      );
    }

    test('makes a draft of what was typed, on calendar days', () {
      final draft = create(due: DateTime(2026, 10, 31, 18));

      expect(draft?.person, 'Sam');
      expect(draft?.amount, rub(10000));
      expect(draft?.startDate, DateTime(2026, 10));
      expect(draft?.dueDate, DateTime(2026, 10, 31));
    });

    test('needs a person of at most fifty characters', () {
      expect(create(person: ''), isNull);
      expect(create(person: '   '), isNull);
      expect(create(person: 'a' * 50), isNotNull);
      expect(create(person: 'a' * 51), isNull);
    });

    test('needs a positive amount', () {
      expect(create(amount: ''), isNull);
      expect(create(amount: '0'), isNull);
      expect(create(amount: 'abc'), isNull);
    });

    test('cannot be due before it starts', () {
      expect(create(due: DateTime(2026, 9, 30)), isNull);
      expect(create(due: DateTime(2026, 10)), isNotNull);
    });

    test('has a note of at most a hundred characters', () {
      expect(create(note: 'a' * 100), isNotNull);
      expect(create(note: 'a' * 101), isNull);
    });
  });

  group('RepaymentDraft.tryCreate', () {
    RepaymentDraft? create(String amount, {Money? max}) {
      return RepaymentDraft.tryCreate(
        amount: amount,
        currency: Currency.rub,
        date: DateTime(2026, 10, 12, 8),
        maxAmount: max ?? rub(6000),
      );
    }

    test('makes a draft of what was typed', () {
      final draft = create('1500.50');

      expect(draft?.amount, const Money(150050, Currency.rub));
      expect(draft?.date, DateTime(2026, 10, 12));
    });

    test('can be as much as what is left, and no more', () {
      expect(create('6000'), isNotNull);
      expect(create('6000.01'), isNull);
    });

    test('needs a positive amount', () {
      expect(create(''), isNull);
      expect(create('0'), isNull);
      expect(create('x'), isNull);
    });
  });

  test('a repayment gives back its draft', () {
    final repayment = sam.repayments.single;

    expect(Repayment.fromDraft(repayment.id, repayment.draft), repayment);
  });
}
