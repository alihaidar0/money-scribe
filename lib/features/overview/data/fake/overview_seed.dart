import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';

/// Invented figures for the fake server. October 2026 is the example of
/// `docs/DESIGN.md`; other months vary a little around it so switching month
/// visibly changes the screen. Never the owner's real figures.
abstract final class OverviewSeed {
  static Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

  static MonthOverview month(YearMonth month, PaymentMode mode) {
    // Which of four patterns the month follows. October 2026 is pattern 2.
    final pattern = (month.year * 12 + month.month) % 4;

    final first = OverviewFigures(
      salary: _rub(43500),
      recurringIncome: _rub(0),
      otherIncome: _rub(0),
      fixedCosts: _rub(-34500),
      purchases: _rub(-8250),
      debtMovements: _rub(const [0, 2500, 4000, 1500][pattern]),
    );
    final second = OverviewFigures(
      salary: _rub(pattern == 1 ? 56550 : 60900),
      recurringIncome: _rub(5000),
      otherIncome: _rub(pattern == 0 ? 2000 : 0),
      fixedCosts: _rub(0),
      purchases: _rub(-10000 - (pattern - 2) * 1500),
      debtMovements: _rub(0),
    );
    final total = OverviewFigures(
      salary: first.salary + second.salary,
      recurringIncome: first.recurringIncome + second.recurringIncome,
      otherIncome: first.otherIncome + second.otherIncome,
      fixedCosts: first.fixedCosts + second.fixedCosts,
      purchases: first.purchases + second.purchases,
      debtMovements: first.debtMovements + second.debtMovements,
    );

    return switch (mode) {
      PaymentMode.onePayment => MonthOverview(month: month, total: total),
      PaymentMode.twoPayments => MonthOverview(
        month: month,
        total: total,
        firstPart: first,
        secondPart: second,
        cycle: PayCycle.twoPayments(
          firstPayDay: PayCycle.defaultFirstPayDay,
          secondPayDay: PayCycle.defaultSecondPayDay,
        ),
      ),
    };
  }

  static List<DebtChoice> debtsToRepay() {
    return [
      DebtChoice(
        id: 'sam',
        person: 'Sam',
        direction: DebtDirection.lent,
        remaining: _rub(6000),
        status: DebtStatus.open,
      ),
      DebtChoice(
        id: 'maria',
        person: 'Maria',
        direction: DebtDirection.lent,
        remaining: _rub(2500),
        status: DebtStatus.overdue,
      ),
    ];
  }
}
