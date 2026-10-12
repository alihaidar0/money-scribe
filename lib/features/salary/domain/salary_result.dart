import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';

/// The lines of a calculated month, each already rounded to the kopeck, so the
/// figures shown add up exactly.
final class SalaryResult extends Equatable {
  new({
    required this.foodAllowance,
    required this.extraHoursPay,
    required this.incomeBeforeTax,
    required this.tax,
    required this.totalAfterTax,
    required List<Money> payments,
  }) : payments = List.unmodifiable(payments),
       assert(
         payments.length == 1 || payments.length == 2,
         'A month is paid in one or two payments',
       ),
       assert(
         payments.fold(
               Money.zero(totalAfterTax.currency),
               (sum, p) => sum + p,
             ) ==
             totalAfterTax,
         'The payments add up to the total after tax',
       );

  /// Working days in the month times the allowance per day (positive).
  final Money foodAllowance;

  /// Extra hours at twice the hourly rate (positive).
  final Money extraHoursPay;

  /// Base salary, food allowance and extra-hours pay together.
  final Money incomeBeforeTax;

  /// The tax withheld from [incomeBeforeTax] (shown as a positive amount).
  final Money tax;

  /// What is paid out: [incomeBeforeTax] minus [tax].
  final Money totalAfterTax;

  /// The pay of each payment, in order: one for the whole month, or the
  /// 1st-15th and then the 16th-end. They always add up to [totalAfterTax].
  final List<Money> payments;

  @override
  List<Object> get props => [
    foodAllowance,
    extraHoursPay,
    incomeBeforeTax,
    tax,
    totalAfterTax,
    payments,
  ];
}
