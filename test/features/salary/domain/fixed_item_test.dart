import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/data/fake/fixed_items_seed.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_summary.dart';
import 'package:money_scribe/features/salary/domain/salary_history_entry.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

const october = YearMonth(2026, 10);

SalaryResult salary(PaymentMode mode) {
  return SalaryHistoryEntry.tryFrom(SalarySeed.month(october, mode)!)!.result;
}

void main() {
  group('FixedItemPart.ofDay', () {
    FixedItemPart ofDay(int day, {int first = 20, int second = 5}) {
      return FixedItemPart.ofDay(day, firstPayDay: first, secondPayDay: second);
    }

    test('is paid from the payment received most recently', () {
      // The first payment on the 20th, the second on the 5th.
      expect(ofDay(13), FixedItemPart.second, reason: 'rent on the 13th');
      expect(ofDay(21), FixedItemPart.first, reason: 'services on the 21st');
    });

    test('the pay days belong to the payment they bring', () {
      expect(ofDay(5), FixedItemPart.second);
      expect(ofDay(20), FixedItemPart.first);
    });

    test('the days before the second payment are still the first part', () {
      expect(ofDay(1), FixedItemPart.first);
      expect(ofDay(4), FixedItemPart.first);
      expect(ofDay(31), FixedItemPart.first);
    });

    test('the days between the two pay days are the second part', () {
      expect(ofDay(6), FixedItemPart.second);
      expect(ofDay(19), FixedItemPart.second);
    });

    test('follows the pay days that were set', () {
      // The first payment on the 25th, the second on the 10th.
      expect(ofDay(10, first: 25, second: 10), FixedItemPart.second);
      expect(ofDay(24, first: 25, second: 10), FixedItemPart.second);
      expect(ofDay(25, first: 25, second: 10), FixedItemPart.first);
      expect(ofDay(3, first: 25, second: 10), FixedItemPart.first);
    });

    test('a second pay day that is not before the first uses 20 and 5', () {
      expect(ofDay(10, first: 10, second: 25), FixedItemPart.second);
      expect(ofDay(21, first: 10, second: 10), FixedItemPart.first);
      expect(ofDay(13, first: 10, second: 10), FixedItemPart.second);
    });
  });

  group('FixedItemDraft.tryCreate', () {
    FixedItemDraft? create({
      String name = 'Gym',
      String amount = '1200.50',
      FixedItemKind kind = FixedItemKind.expense,
      FixedItemPart part = FixedItemPart.first,
    }) {
      return FixedItemDraft.tryCreate(
        name: name,
        amount: amount,
        currency: Currency.rub,
        kind: kind,
        part: part,
      );
    }

    test('makes a draft of what was typed', () {
      final draft = create(
        kind: FixedItemKind.income,
        part: FixedItemPart.second,
      );

      expect(draft?.name, 'Gym');
      expect(draft?.amount, const Money(120050, Currency.rub));
      expect(draft?.kind, FixedItemKind.income);
      expect(draft?.part, FixedItemPart.second);
    });

    test('a dated item keeps the part it was given, whatever its day', () {
      final draft = FixedItemDraft.tryCreate(
        name: 'Gym',
        amount: '10',
        currency: Currency.rub,
        kind: FixedItemKind.expense,
        part: FixedItemPart.second,
        day: 25,
      );

      expect(draft?.part, FixedItemPart.second);
      expect(draft?.day, 25);
    });

    test('trims the name', () {
      expect(create(name: '  Gym  ')?.name, 'Gym');
    });

    test('needs a name', () {
      expect(create(name: ''), isNull);
      expect(create(name: '   '), isNull);
    });

    test('has a name of at most fifty characters', () {
      expect(create(name: 'a' * 50), isNotNull);
      expect(create(name: 'a' * 51), isNull);
    });

    test('needs an amount that is a positive number', () {
      expect(create(amount: ''), isNull);
      expect(create(amount: 'abc'), isNull);
      expect(create(amount: '0'), isNull);
      expect(create(amount: '0.00'), isNull);
      expect(create(amount: '-5'), isNull);
      expect(create(amount: '0.01'), isNotNull);
    });
  });

  group('FixedItem', () {
    const rent = FixedItem(
      id: 'a',
      name: 'Rent',
      amount: Money(3000000, Currency.rub),
      kind: FixedItemKind.expense,
      part: FixedItemPart.first,
    );

    test('an expense has a negative signed amount', () {
      expect(rent.signedAmount, rub(-30000));
    });

    test('an income keeps its sign', () {
      final scholarship = FixedItem.fromDraft(
        'b',
        FixedItemDraft(
          name: 'Scholarship',
          amount: rub(5000),
          kind: FixedItemKind.income,
        ),
      );

      expect(scholarship.signedAmount, rub(5000));
    });

    test('its draft is what it is made of', () {
      expect(FixedItem.fromDraft('a', rent.draft), rent);
    });
  });

  group('FixedItemsSummary', () {
    final items = FixedItemsSeed.items(october);

    FixedItemsSummary summarize({
      required PaymentMode mode,
      FixedItemPart part = FixedItemPart.first,
      bool withSalary = true,
      List<FixedItem>? only,
    }) {
      return FixedItemsSummary.of(
        items: only ?? items,
        salary: withSalary ? salary(mode) : null,
        currency: Currency.rub,
        twoPayments: mode == PaymentMode.twoPayments,
        part: part,
      );
    }

    test('one payment: the salary plus the income minus the costs', () {
      final summary = summarize(mode: PaymentMode.onePayment);

      expect(summary.pay, rub(104400));
      expect(summary.balance, rub(74900));
      expect(summary.wholeMonth, isNull);
    });

    test('one payment ignores the parts of the items', () {
      final first = summarize(mode: PaymentMode.onePayment);
      final second = summarize(
        mode: PaymentMode.onePayment,
        part: FixedItemPart.second,
      );

      expect(second, first);
    });

    test('two payments: the first part counts its own items', () {
      final summary = summarize(mode: PaymentMode.twoPayments);

      expect(summary.pay, rub(43500));
      expect(summary.balance, rub(9000));
      expect(summary.wholeMonth, rub(74900));
    });

    test('two payments: the second part counts its own items', () {
      final summary = summarize(
        mode: PaymentMode.twoPayments,
        part: FixedItemPart.second,
      );

      expect(summary.pay, rub(60900));
      expect(summary.balance, rub(65900));
      expect(summary.wholeMonth, rub(74900));
    });

    test('the two parts add up to the whole month', () {
      final first = summarize(mode: PaymentMode.twoPayments);
      final second = summarize(
        mode: PaymentMode.twoPayments,
        part: FixedItemPart.second,
      );

      expect(first.balance + second.balance, first.wholeMonth);
    });

    test('a month with no saved salary has no pay', () {
      final summary = summarize(
        mode: PaymentMode.onePayment,
        withSalary: false,
      );

      expect(summary.pay, rub(0));
      expect(summary.balance, rub(-29500));
    });

    test('a month with no items has the pay as its balance', () {
      final summary = summarize(mode: PaymentMode.onePayment, only: const []);

      expect(summary.balance, rub(104400));
    });

    test('shown lists the items of one part, or all of them', () {
      List<String> names({
        required bool twoPayments,
        required FixedItemPart part,
      }) {
        return FixedItemsSummary.shown(
          items,
          twoPayments: twoPayments,
          part: part,
        ).map((item) => item.name).toList();
      }

      expect(names(twoPayments: false, part: FixedItemPart.second), [
        'Scholarship',
        'Rent',
        'Services',
      ]);
      expect(names(twoPayments: true, part: FixedItemPart.first), [
        'Rent',
        'Services',
      ]);
      expect(names(twoPayments: true, part: FixedItemPart.second), [
        'Scholarship',
      ]);
    });
  });
}
