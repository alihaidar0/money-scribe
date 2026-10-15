import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

/// Invented debts for the fake server, from the sample of `docs/DESIGN.md`.
/// The ids are the ones the Overview offers when a repayment is added. Never
/// the owner's real figures.
abstract final class DebtsSeed {
  static Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

  /// The debts, in the order they were added.
  static List<Debt> debts() {
    return [
      Debt(
        id: 'sam',
        direction: DebtDirection.lent,
        person: 'Sam',
        amount: _rub(10000),
        startDate: DateTime(2026, 10),
        dueDate: DateTime(2026, 10, 31),
        note: 'Lunch money',
        repayments: [
          Repayment(
            id: 'sam-repayment-1',
            amount: _rub(4000),
            date: DateTime(2026, 10, 12),
          ),
        ],
      ),
      Debt(
        id: 'maria',
        direction: DebtDirection.lent,
        person: 'Maria',
        amount: _rub(2500),
        startDate: DateTime(2026, 9, 15),
        dueDate: DateTime(2026, 9, 30),
      ),
      Debt(
        id: 'anna',
        direction: DebtDirection.borrowed,
        person: 'Anna',
        amount: _rub(3000),
        startDate: DateTime(2026, 9),
        repayments: [
          Repayment(
            id: 'anna-repayment-1',
            amount: _rub(3000),
            date: DateTime(2026, 9, 20),
          ),
        ],
      ),
    ];
  }
}
