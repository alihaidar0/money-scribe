import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

/// Invented salaries for the fake server. October 2026 is the example of
/// `docs/DESIGN.md`; the months before it vary a little. Never the owner's real
/// figures.
abstract final class SalarySeed {
  /// The months that have a saved salary, newest first.
  static const months = [
    YearMonth(2026, 10),
    YearMonth(2026, 9),
    YearMonth(2026, 8),
  ];

  static Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

  /// The saved salary of [month], or `null` for a month outside [months].
  static SalaryMonth? month(YearMonth month, PaymentMode mode) {
    if (!months.contains(month)) return null;

    // September had half the extra hours of the other two months.
    final extraHours = month == const YearMonth(2026, 9) ? 4 : 8;
    return SalaryMonth(
      month: month,
      inputs: SalaryInputs(
        baseSalary: _rub(100000),
        foodPerDay: _rub(500),
        workingDaysInMonth: 20,
        workingDaysFirstHalf: 10,
        workingHoursInMonth: 160,
        extraHoursHundredths: extraHours * 100,
        taxRateBasisPoints: 1300,
        paymentMode: mode,
      ),
      firstPayDay: 20,
      secondPayDay: 5,
    );
  }
}
