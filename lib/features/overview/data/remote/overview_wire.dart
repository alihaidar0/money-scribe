import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';

/// Turns what the server sends about the Overview into the types of the app.
/// An answer the app cannot read at all (an unknown currency, an amount that
/// does not fit its currency) breaks the contract, so it is a
/// `ServerException`.
abstract final class OverviewWire {
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

  /// The figures of a block. The server sends the costs and the repayments as
  /// positive amounts; the app keeps spending negative, and the debt movement
  /// is what was received less what was repaid.
  static OverviewFigures figures(api.OverviewBlock wire, Currency currency) {
    Money money(String text) => amount(text, currency);
    return OverviewFigures(
      salary: money(wire.salary),
      recurringIncome: money(wire.recurringIncome),
      otherIncome: money(wire.incomeTransactions),
      fixedCosts: -money(wire.fixedCosts),
      purchases: -money(wire.purchases),
      debtMovements:
          money(wire.debtRepaymentsReceived) - money(wire.debtRepaymentsMade),
      reportedBalance: money(wire.balance),
    );
  }

  /// The overview, or `null` for a month with nothing in it. A month paid in
  /// two payments has both parts, a month paid once has neither; one part
  /// alone breaks the contract.
  static MonthOverview? overview(api.Overview wire, YearMonth month) {
    if (!wire.hasData) return null;
    final currency = OverviewWire.currency(wire.currency);
    final first = wire.firstPart;
    final second = wire.secondPart;
    if ((first == null) != (second == null)) throw const ServerException();
    return MonthOverview(
      month: month,
      total: figures(wire.total, currency),
      firstPart: first == null ? null : figures(first, currency),
      secondPart: second == null ? null : figures(second, currency),
      hasOtherCurrencies: wire.currencies.any(
        (other) => other != wire.currency,
      ),
    );
  }

  /// The debts that can be repaid, those past their due day first, as the
  /// debts report lists them in every currency.
  static List<DebtChoice> debtChoices(api.DebtsReport wire) {
    DebtChoice choice(api.DebtLine line, Currency currency, DebtStatus status) {
      return DebtChoice(
        id: line.id,
        person: line.person,
        direction: switch (line.direction) {
          api.DebtDirectionEnum.lent => DebtDirection.lent,
          api.DebtDirectionEnum.borrowed => DebtDirection.borrowed,
          api.DebtDirectionEnum.$unknown => throw const ServerException(),
        },
        remaining: amount(line.remaining, currency),
        status: status,
      );
    }

    return [
      for (final block in wire.byCurrency) ...[
        for (final line in block.overdue)
          choice(line, currency(block.currency), DebtStatus.overdue),
        for (final line in block.open)
          choice(line, currency(block.currency), DebtStatus.open),
      ],
    ];
  }
}
