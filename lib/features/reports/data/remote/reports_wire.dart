import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/features/reports/domain/category_spend.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';

/// Turns what the server sends for the Reports into the types of the app. An
/// answer the app cannot read at all (an unknown currency, an amount that does
/// not fit its currency) breaks the contract, so it is a `ServerException`.
abstract final class ReportsWire {
  static Currency currency(api.CurrencyEnum wire) {
    return Currency.tryFromCode(wire.json ?? '') ??
        (throw const ServerException());
  }

  /// The currency as the query of a call takes it.
  static api.Currency currencyToQuery(Currency currency) {
    final wire = api.Currency.fromJson(currency.code);
    if (wire == api.Currency.$unknown) throw const ServerException();
    return wire;
  }

  static Money amount(String wire, Currency currency) {
    return Money.tryParse(wire, currency) ?? (throw const ServerException());
  }

  static CategoryIcon icon(String slug) {
    for (final icon in CategoryIcon.values) {
      if (icon.name == slug) return icon;
    }
    return CategoryIcon.other;
  }

  static CategorySpend category(api.CategorySpend wire, Currency currency) {
    return CategorySpend(
      categoryId: wire.categoryId,
      key: wire.categoryKey,
      name: wire.name,
      icon: icon(wire.icon),
      amount: amount(wire.amount, currency),
    );
  }

  /// One period of the report: the income and the spending are the
  /// Overview's, so the reports agree with it (income is the pay, the
  /// recurring income and the income transactions; spending is the fixed
  /// costs and the purchases). What the spending went on is the month
  /// report's categories, with one more slice for the fixed costs, so the
  /// slices add up to the spending. The categories come biggest first, and the
  /// fixed costs keep their place by size.
  static PeriodReport period({
    required api.OverviewBlock overview,
    required List<api.CategorySpend> categories,
    required Currency currency,
  }) {
    Money money(String text) => amount(text, currency);
    final fixedCosts = money(overview.fixedCosts);
    final slices = [
      for (final category in categories)
        if (money(category.amount).isPositive)
          ReportsWire.category(category, currency),
      if (fixedCosts.isPositive) CategorySpend.fixedCosts(fixedCosts),
    ];
    // Stable: equal amounts keep the order the server gave, the fixed costs
    // last.
    final indexed = [for (var i = 0; i < slices.length; i++) (i, slices[i])]
      ..sort((a, b) {
        final byAmount = b.$2.amount.compareTo(a.$2.amount);
        return byAmount != 0 ? byAmount : a.$1.compareTo(b.$1);
      });
    return PeriodReport(
      income:
          money(overview.salary) +
          money(overview.recurringIncome) +
          money(overview.incomeTransactions),
      spent: fixedCosts + money(overview.purchases),
      categories: [for (final entry in indexed) entry.$2],
    );
  }

  /// The report of a month, or `null` for a month with nothing in it. A month
  /// paid in two payments has both parts, in the Overview and in the report;
  /// one part alone breaks the contract.
  static MonthReport? month({
    required api.Overview overview,
    required api.MonthReport report,
    required YearMonth month,
    required PayCycle partsCycle,
  }) {
    if (!overview.hasData) return null;
    final currency = ReportsWire.currency(overview.currency);
    final first = overview.firstPart;
    final second = overview.secondPart;
    final firstSlice = report.firstPart;
    final secondSlice = report.secondPart;
    final hasParts = first != null && second != null;
    if (hasParts != (firstSlice != null && secondSlice != null) ||
        (first == null) != (second == null)) {
      throw const ServerException();
    }
    return MonthReport(
      month: month,
      total: period(
        overview: overview.total,
        categories: report.categories,
        currency: currency,
      ),
      firstPart: hasParts
          ? period(
              overview: first,
              categories: firstSlice!.categories,
              currency: currency,
            )
          : null,
      secondPart: hasParts
          ? period(
              overview: second,
              categories: secondSlice!.categories,
              currency: currency,
            )
          : null,
      cycle: hasParts ? partsCycle : const PayCycle.onePayment(),
      hasOtherCurrencies: overview.currencies.any(
        (other) => other != overview.currency,
      ),
    );
  }

  /// Where the debts stand in [currency]: its totals and its unsettled debts.
  /// Debts in other currencies are left out, and the report says that some
  /// exist.
  static DebtsReport debts(api.DebtsReport wire, Currency currency) {
    DebtReportItem item(api.DebtLine line, DebtStatus status) {
      return DebtReportItem(
        id: line.id,
        person: line.person,
        direction: switch (line.direction) {
          api.DebtDirectionEnum.lent => DebtDirection.lent,
          api.DebtDirectionEnum.borrowed => DebtDirection.borrowed,
          api.DebtDirectionEnum.$unknown => throw const ServerException(),
        },
        remaining: amount(line.remaining, currency),
        status: status,
        dueDate: line.dueDate == null
            ? null
            : DateTime(
                line.dueDate!.year,
                line.dueDate!.month,
                line.dueDate!.day,
              ),
      );
    }

    final own = [
      for (final block in wire.byCurrency)
        if (ReportsWire.currency(block.currency) == currency) block,
    ];
    final block = own.firstOrNull;
    return DebtsReport(
      owedToYou: block == null
          ? Money.zero(currency)
          : amount(block.owedToYou, currency),
      youOwe: block == null
          ? Money.zero(currency)
          : amount(block.youOwe, currency),
      overdue: [
        if (block != null)
          for (final line in block.overdue) item(line, DebtStatus.overdue),
      ],
      open: [
        if (block != null)
          for (final line in block.open) item(line, DebtStatus.open),
      ],
      hasOtherCurrencies: wire.byCurrency.length > own.length,
    );
  }
}
