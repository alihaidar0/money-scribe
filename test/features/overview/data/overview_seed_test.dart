import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/overview/data/fake/overview_seed.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  const october = YearMonth(2026, 10);

  group('October 2026, the example of the design', () {
    final month = OverviewSeed.month(october, PaymentMode.onePayment);

    test('has the lines of the design', () {
      expect(month.total.salary, rub(104400));
      expect(month.total.recurringIncome, rub(5000));
      expect(month.total.fixedCosts, rub(-34500));
      expect(month.total.purchases, rub(-18250));
      expect(month.total.debtMovements, rub(4000));
    });

    test('adds up to the balance of the design', () {
      expect(month.total.income, rub(109400));
      expect(month.total.spent, rub(-52750));
      expect(month.total.balance, rub(60650));
    });

    test('has no parts for one payment', () {
      expect(month.hasParts, isFalse);
    });

    test('has the two parts of the design for two payments', () {
      final twoPayments = OverviewSeed.month(october, PaymentMode.twoPayments);
      final first = twoPayments.firstPart!;
      final second = twoPayments.secondPart!;

      expect(first.balance, rub(4750));
      expect(first.income, rub(43500));
      expect(first.spent, rub(-42750));
      expect(first.debtMovements, rub(4000));
      expect(second.balance, rub(55900));
      expect(second.income, rub(65900));
      expect(second.spent, rub(-10000));
      expect(second.debtMovements, rub(0));
      expect(twoPayments.total, month.total);
    });
  });

  test('the parts of every month add up to the month', () {
    var month = const YearMonth(2025, 1);
    for (var i = 0; i < 36; i++) {
      final overview = OverviewSeed.month(month, PaymentMode.twoPayments);
      final first = overview.firstPart!;
      final second = overview.secondPart!;

      expect(
        first.balance + second.balance,
        overview.total.balance,
        reason: '$month',
      );
      expect(first.income + second.income, overview.total.income);
      expect(first.spent + second.spent, overview.total.spent);
      month = month.next;
    }
  });

  test('other months differ from October', () {
    final september = OverviewSeed.month(
      october.previous,
      PaymentMode.onePayment,
    );
    final august = OverviewSeed.month(
      october.previous.previous,
      PaymentMode.onePayment,
    );
    final balances = {
      OverviewSeed.month(october, PaymentMode.onePayment).total.balance,
      september.total.balance,
      august.total.balance,
    };

    expect(balances, hasLength(3));
  });

  test('offers a lent and an overdue debt to repay', () {
    final debts = OverviewSeed.debtsToRepay();

    expect(debts.map((debt) => debt.person), ['Sam', 'Maria']);
    expect(debts.first.remaining, rub(6000));
    expect(debts.last.remaining, rub(2500));
  });
}
