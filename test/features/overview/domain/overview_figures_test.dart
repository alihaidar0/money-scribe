import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

OverviewFigures figures({Money? reportedBalance}) {
  return OverviewFigures(
    salary: rub(1000),
    recurringIncome: rub(100),
    otherIncome: rub(50),
    fixedCosts: rub(-300),
    purchases: rub(-120),
    debtMovements: rub(25),
    reportedBalance: reportedBalance,
  );
}

void main() {
  group('OverviewFigures', () {
    test(
      'the income is the pay, the recurring income and the other income',
      () {
        expect(figures().income, rub(1150));
      },
    );

    test('the spending is the fixed costs and the purchases', () {
      expect(figures().spent, rub(-420));
    });

    test(
      'the balance adds the income, the spending and the debt movements',
      () {
        expect(figures().balance, rub(755));
      },
    );

    test('the balance the server reported is the one shown', () {
      expect(figures(reportedBalance: rub(700)).balance, rub(700));
    });

    test('the reported balance tells two sets of figures apart', () {
      expect(figures(), isNot(figures(reportedBalance: rub(755))));
    });
  });
}
