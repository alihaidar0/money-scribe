import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// The outcome of [SalaryCalculator.calculate].
sealed class SalaryCalculation {
  const new();
}

/// The inputs were valid.
final class SalaryComputed extends SalaryCalculation {
  const new(this.result);

  final SalaryResult result;
}

/// The inputs cannot be calculated; [problems] says why.
final class SalaryRejected extends SalaryCalculation {
  const new(this.problems);

  final Set<SalaryInputProblem> problems;
}

/// The monthly salary model. Every line is rounded to the kopeck on its own
/// (`Money.scaled`, half a kopeck rounds up) and each line is computed from the
/// already rounded lines it is made of, so the figures on screen add up to the
/// kopeck. Rounding itself lives in `Money` and nowhere else.
abstract final class SalaryCalculator {
  static SalaryCalculation calculate(SalaryInputs inputs) {
    final problems = inputs.problems;
    if (problems.isNotEmpty) return SalaryRejected(problems);

    final base = inputs.baseSalary;

    final foodAllowance = inputs.foodPerDay * inputs.workingDaysInMonth;
    // Twice the hourly rate (base / hours) for each extra hour.
    final extraHoursPay = base.scaled(
      2 * inputs.extraHoursHundredths,
      inputs.workingHoursInMonth * 100,
    );
    final incomeBeforeTax = base + foodAllowance + extraHoursPay;
    final tax = incomeBeforeTax.scaled(
      inputs.taxRateBasisPoints,
      SalaryInputs.fullTaxRate,
    );
    final totalAfterTax = incomeBeforeTax - tax;

    return SalaryComputed(
      SalaryResult(
        foodAllowance: foodAllowance,
        extraHoursPay: extraHoursPay,
        incomeBeforeTax: incomeBeforeTax,
        tax: tax,
        totalAfterTax: totalAfterTax,
        payments: _payments(inputs, totalAfterTax),
      ),
    );
  }

  /// The payments of the month. Each one but the last is its share of the
  /// taxed base salary, rounded once and never more than what is left to pay;
  /// the last is what remains of the total, so a month paid in one payment is
  /// simply the total and no payment is ever negative.
  static List<Money> _payments(SalaryInputs inputs, Money totalAfterTax) {
    final daysBeforeLastPayment = switch (inputs.paymentMode) {
      PaymentMode.onePayment => const <int>[],
      PaymentMode.twoPayments => [inputs.workingDaysFirstHalf],
    };

    var remaining = totalAfterTax;
    final payments = <Money>[];
    for (final days in daysBeforeLastPayment) {
      final share = inputs.baseSalary.scaled(
        days * (SalaryInputs.fullTaxRate - inputs.taxRateBasisPoints),
        inputs.workingDaysInMonth * SalaryInputs.fullTaxRate,
      );
      // Rounding the tax and the share separately can leave the share a
      // kopeck above what is left to pay; then the last payment is zero, not
      // negative.
      final payment = share > remaining ? remaining : share;
      payments.add(payment);
      remaining -= payment;
    }
    return [...payments, remaining];
  }
}
