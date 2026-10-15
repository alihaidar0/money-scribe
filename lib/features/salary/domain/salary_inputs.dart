import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// Why a set of [SalaryInputs] cannot be calculated. The form maps each one to
/// the field it belongs to.
enum SalaryInputProblem {
  baseSalaryNotPositive,
  foodPerDayNegative,
  workingDaysOutOfRange,
  firstHalfDaysOutOfRange,
  workingHoursNotPositive,
  extraHoursNegative,
  taxRateOutOfRange,
}

/// What a month's pay is calculated from. Amounts are [Money]; the two
/// quantities that can have a fraction are whole numbers of a smaller unit, so
/// that no `double` is involved: [extraHoursHundredths] and
/// [taxRateBasisPoints].
final class SalaryInputs extends Equatable {
  new({
    required this.baseSalary,
    required this.foodPerDay,
    required this.workingDaysInMonth,
    required this.workingHoursInMonth,
    required this.extraHoursHundredths,
    required this.taxRateBasisPoints,
    this.paymentMode = PaymentMode.onePayment,
    this.workingDaysFirstHalf = 0,
  }) : assert(
         baseSalary.currency == foodPerDay.currency,
         'The base salary and the food allowance share one currency',
       );

  /// The most working days a month can have.
  static const maxWorkingDays = 31;

  /// A tax rate of 100 %, in [taxRateBasisPoints].
  static const fullTaxRate = 10000;

  /// The taxed base salary (the "net salary" of the spreadsheet).
  final Money baseSalary;

  /// Food allowance for one working day.
  final Money foodPerDay;

  /// Working days in the whole month. The food allowance is paid for each.
  final int workingDaysInMonth;

  /// Working hours in the whole month. The extra-hours rate is derived from it.
  final int workingHoursInMonth;

  /// Extra hours worked, in hundredths of an hour (7.5 hours is 750).
  final int extraHoursHundredths;

  /// The tax rate in hundredths of a percent (13 % is 1300).
  final int taxRateBasisPoints;

  final PaymentMode paymentMode;

  /// Working days from the 1st to the 15th. Used only when the month is paid
  /// in [PaymentMode.twoPayments], where it sets the size of the first pay.
  final int workingDaysFirstHalf;

  /// Everything wrong with these inputs; empty when they can be calculated.
  Set<SalaryInputProblem> get problems => {
    if (!baseSalary.isPositive) SalaryInputProblem.baseSalaryNotPositive,
    if (foodPerDay.isNegative) SalaryInputProblem.foodPerDayNegative,
    if (workingDaysInMonth < 1 || workingDaysInMonth > maxWorkingDays)
      SalaryInputProblem.workingDaysOutOfRange,
    if (paymentMode == PaymentMode.twoPayments &&
        (workingDaysFirstHalf < 0 || workingDaysFirstHalf > workingDaysInMonth))
      SalaryInputProblem.firstHalfDaysOutOfRange,
    if (workingHoursInMonth < 1) SalaryInputProblem.workingHoursNotPositive,
    if (extraHoursHundredths < 0) SalaryInputProblem.extraHoursNegative,
    if (taxRateBasisPoints < 0 || taxRateBasisPoints > fullTaxRate)
      SalaryInputProblem.taxRateOutOfRange,
  };

  @override
  List<Object> get props => [
    baseSalary,
    foodPerDay,
    workingDaysInMonth,
    workingHoursInMonth,
    extraHoursHundredths,
    taxRateBasisPoints,
    paymentMode,
    workingDaysFirstHalf,
  ];
}
