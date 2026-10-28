import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_figures.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// Turns what the server sends into the types of the app, and back. An answer
/// the app cannot read (an unknown currency, an amount that does not fit its
/// currency, a month that is not `YYYY-MM`) breaks the contract, so it is a
/// `ServerException`.
abstract final class SalaryWire {
  static Currency currency(api.CurrencyEnum wire) {
    return Currency.tryFromCode(wire.json ?? '') ??
        (throw const ServerException());
  }

  static api.CurrencyEnum currencyToWire(Currency currency) {
    final wire = api.CurrencyEnum.fromJson(currency.code);
    if (wire == api.CurrencyEnum.$unknown) throw const ServerException();
    return wire;
  }

  /// An amount as the server writes it: a decimal string with the digits of
  /// the currency.
  static Money money(String text, Currency currency) {
    return Money.tryParse(text, currency) ?? (throw const ServerException());
  }

  static PaymentMode paymentMode(api.PaymentModeEnum wire) {
    return switch (wire) {
      api.PaymentModeEnum.onePayment => PaymentMode.onePayment,
      api.PaymentModeEnum.twoPayments => PaymentMode.twoPayments,
      api.PaymentModeEnum.$unknown => throw const ServerException(),
    };
  }

  static api.PaymentModeEnum paymentModeToWire(PaymentMode mode) {
    return switch (mode) {
      PaymentMode.onePayment => api.PaymentModeEnum.onePayment,
      PaymentMode.twoPayments => api.PaymentModeEnum.twoPayments,
    };
  }

  static SalaryMonth month(api.SalaryMonth wire) {
    final month = YearMonth.tryParse(wire.month);
    if (month == null) throw const ServerException();
    final currency = SalaryWire.currency(wire.currency);
    final mode = paymentMode(wire.paymentMode);
    return SalaryMonth(
      month: month,
      inputs: SalaryInputs(
        baseSalary: money(wire.baseSalary, currency),
        foodPerDay: money(wire.foodPerDay, currency),
        workingDaysInMonth: wire.workingDaysInMonth,
        workingHoursInMonth: wire.workingHoursInMonth,
        extraHoursHundredths: wire.extraHoursHundredths,
        taxRateBasisPoints: wire.taxRateBasisPoints,
        paymentMode: mode,
        workingDaysFirstHalf: wire.workingDaysFirstHalf ?? 0,
      ),
      firstPayDay: wire.firstPayDay,
      secondPayDay: wire.secondPayDay,
      version: wire.version,
      figures: figures(wire, currency, mode),
    );
  }

  /// What the server calculated for [wire]. The payments must be the ones
  /// the month's [mode] has and add up to the total after tax; otherwise the
  /// answer breaks the contract.
  static SalaryFigures figures(
    api.SalaryMonth wire,
    Currency currency,
    PaymentMode mode,
  ) {
    Money? payment(api.PartEnum part) {
      for (final entry in wire.payments) {
        if (entry.partValue == part) return money(entry.amount, currency);
      }
      return null;
    }

    final first = payment(api.PartEnum.first);
    final second = payment(api.PartEnum.second);
    final twoPayments = mode == PaymentMode.twoPayments;
    final payments = [?first, ?second];
    if (first == null ||
        (second != null) != twoPayments ||
        wire.payments.length != payments.length) {
      throw const ServerException();
    }

    final results = wire.results;
    final totalAfterTax = money(results.totalAfterTax, currency);
    final paid = payments.fold(Money.zero(currency), (sum, pay) => sum + pay);
    if (paid != totalAfterTax) throw const ServerException();

    final balances = wire.balances;
    final secondBalance = balances.second;
    return SalaryFigures(
      result: SalaryResult(
        foodAllowance: money(results.foodAllowance, currency),
        extraHoursPay: money(results.extraHoursPay, currency),
        incomeBeforeTax: money(results.incomeBeforeTax, currency),
        tax: money(results.tax, currency),
        totalAfterTax: totalAfterTax,
        payments: payments,
      ),
      balances: SalaryBalances(
        first: money(balances.first, currency),
        second: secondBalance == null ? null : money(secondBalance, currency),
        month: money(balances.month, currency),
      ),
    );
  }

  /// The inputs of a month to save. The days of the first half go only with
  /// two payments; the server refuses them otherwise.
  static api.SalaryMonthInputRequest monthInput(SalaryMonth month) {
    final inputs = month.inputs;
    return api.SalaryMonthInputRequest(
      currency: currencyToWire(inputs.baseSalary.currency),
      baseSalary: inputs.baseSalary.toDecimalString(),
      foodPerDay: inputs.foodPerDay.toDecimalString(),
      workingDaysInMonth: inputs.workingDaysInMonth,
      workingHoursInMonth: inputs.workingHoursInMonth,
      extraHoursHundredths: inputs.extraHoursHundredths,
      taxRateBasisPoints: inputs.taxRateBasisPoints,
      paymentMode: paymentModeToWire(inputs.paymentMode),
      workingDaysFirstHalf: inputs.paymentMode == PaymentMode.twoPayments
          ? inputs.workingDaysFirstHalf
          : null,
      firstPayDay: month.firstPayDay,
      secondPayDay: month.secondPayDay,
    );
  }

  static SalaryDefaults defaults(api.Defaults wire) {
    final currency = SalaryWire.currency(wire.currency);
    final baseSalary = wire.baseSalary;
    final foodPerDay = wire.foodPerDay;
    return SalaryDefaults(
      paymentMode: paymentMode(wire.paymentMode),
      firstPayDay: wire.firstPayDay,
      secondPayDay: wire.secondPayDay,
      currency: currency,
      baseSalary: baseSalary == null ? null : money(baseSalary, currency),
      foodPerDay: foodPerDay == null ? null : money(foodPerDay, currency),
      workingHoursInMonth: wire.workingHoursInMonth,
      taxRateBasisPoints: wire.taxRateBasisPoints,
    );
  }

  static FixedItem fixedItem(api.FixedItem wire) {
    final currency = SalaryWire.currency(wire.currency);
    return FixedItem(
      id: wire.id,
      name: wire.name,
      amount: money(wire.amount, currency),
      kind: switch (wire.kind) {
        api.KindEnum.income => FixedItemKind.income,
        api.KindEnum.expense => FixedItemKind.expense,
        api.KindEnum.$unknown => throw const ServerException(),
      },
      part: switch (wire.partValue) {
        api.PartEnum.first => FixedItemPart.first,
        api.PartEnum.second => FixedItemPart.second,
        api.PartEnum.$unknown => throw const ServerException(),
      },
      day: wire.day,
      version: wire.version,
    );
  }

  static api.KindEnum kindToWire(FixedItemKind kind) {
    return switch (kind) {
      FixedItemKind.income => api.KindEnum.income,
      FixedItemKind.expense => api.KindEnum.expense,
    };
  }

  static api.PartEnum partToWire(FixedItemPart part) {
    return switch (part) {
      FixedItemPart.first => api.PartEnum.first,
      FixedItemPart.second => api.PartEnum.second,
    };
  }
}
