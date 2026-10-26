import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/overview/data/fake/fake_overview_repository.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';
import 'package:money_scribe/features/reports/data/fake/fake_reports_repository.dart';
import 'package:money_scribe/features/reports/domain/category_spend.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

/// The fake Overview, but of a month with 2,000.00 of income transactions and
/// records in another currency, as a server with such an account answers.
class OtherCurrencyOverviewRepository extends FakeOverviewRepository {
  new({required super.demo});

  @override
  Future<MonthOverview?> month(YearMonth month) async {
    final seeded = await super.month(month);
    if (seeded == null) return null;
    final total = seeded.total;
    return MonthOverview(
      month: month,
      total: OverviewFigures(
        salary: total.salary,
        recurringIncome: total.recurringIncome,
        otherIncome: _rub(2000),
        fixedCosts: total.fixedCosts,
        purchases: total.purchases,
        debtMovements: total.debtMovements,
      ),
      hasOtherCurrencies: true,
    );
  }
}

/// The fake Reports, but of a month whose spending has a slice of fixed
/// costs and records in another currency, and debts in another currency.
class OtherCurrencyReportsRepository extends FakeReportsRepository {
  new({required super.demo});

  @override
  Future<MonthReport?> month(YearMonth month) async {
    final seeded = await super.month(month);
    if (seeded == null) return null;
    return MonthReport(
      month: month,
      total: PeriodReport(
        income: _rub(100000),
        spent: _rub(12000),
        categories: [
          CategorySpend.fixedCosts(_rub(8000)),
          CategorySpend(
            categoryId: 'pets',
            name: 'Pets',
            icon: seeded.total.categories.first.icon,
            amount: _rub(4000),
          ),
        ],
      ),
      hasOtherCurrencies: true,
    );
  }

  @override
  Future<DebtsReport> debts() async {
    final seeded = await super.debts();
    return DebtsReport(
      owedToYou: seeded.owedToYou,
      youOwe: seeded.youOwe,
      overdue: seeded.overdue,
      open: seeded.open,
      hasOtherCurrencies: true,
    );
  }
}
