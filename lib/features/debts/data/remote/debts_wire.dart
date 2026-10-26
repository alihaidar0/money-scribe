import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

/// Turns what the server sends about debts and repayments into the types of
/// the app, and back. An answer the app cannot read at all (an unknown
/// currency or direction, an amount that does not fit its currency) breaks the
/// contract, so it is a `ServerException`; a status the app does not know yet
/// is worked out by the app instead.
abstract final class DebtsWire {
  static Currency currency(api.CurrencyEnum wire) {
    return Currency.tryFromCode(wire.json ?? '') ??
        (throw const ServerException());
  }

  static api.CurrencyEnum currencyToWire(Currency currency) {
    final wire = api.CurrencyEnum.fromJson(currency.code);
    if (wire == api.CurrencyEnum.$unknown) throw const ServerException();
    return wire;
  }

  static DebtDirection direction(api.DebtDirectionEnum wire) {
    return switch (wire) {
      api.DebtDirectionEnum.lent => DebtDirection.lent,
      api.DebtDirectionEnum.borrowed => DebtDirection.borrowed,
      api.DebtDirectionEnum.$unknown => throw const ServerException(),
    };
  }

  static api.DebtDirectionEnum directionToWire(DebtDirection direction) {
    return switch (direction) {
      DebtDirection.lent => api.DebtDirectionEnum.lent,
      DebtDirection.borrowed => api.DebtDirectionEnum.borrowed,
    };
  }

  /// The status the server worked out, or `null` for one the app does not
  /// know.
  static DebtStatus? status(api.DebtStatusEnum wire) {
    return switch (wire) {
      api.DebtStatusEnum.open => DebtStatus.open,
      api.DebtStatusEnum.overdue => DebtStatus.overdue,
      api.DebtStatusEnum.settled => DebtStatus.settled,
      api.DebtStatusEnum.$unknown => null,
    };
  }

  /// A day as a calendar day: midnight of the day, whatever the zone.
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Money amount(String wire, Currency currency) {
    return Money.tryParse(wire, currency) ?? (throw const ServerException());
  }

  static Repayment repayment(api.Repayment wire, Currency currency) {
    return Repayment(
      id: wire.id,
      amount: amount(wire.amount, currency),
      date: day(wire.date),
      version: wire.version,
    );
  }

  static Debt debt(api.Debt wire) {
    final currency = DebtsWire.currency(wire.currency);
    return Debt(
      id: wire.id,
      direction: direction(wire.direction),
      person: wire.person,
      amount: amount(wire.amount, currency),
      startDate: day(wire.startDate),
      dueDate: wire.dueDate == null ? null : day(wire.dueDate!),
      note: wire.note,
      repayments: [
        for (final item in wire.repayments) repayment(item, currency),
      ],
      version: wire.version,
      reportedStatus: status(wire.status),
    );
  }
}
