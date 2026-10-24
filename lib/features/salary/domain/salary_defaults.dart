import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// How a new, empty month starts. The server answers it: the account's pay
/// schedule, then what the most recent saved month held. What changes every
/// month (the working days, the extra hours) is never carried over.
final class SalaryDefaults extends Equatable {
  const new({
    this.paymentMode = PaymentMode.onePayment,
    this.firstPayDay = 20,
    this.secondPayDay = 5,
    this.currency = Currency.rub,
    this.baseSalary,
    this.foodPerDay,
    this.workingHoursInMonth,
    this.taxRateBasisPoints = 1300,
  });

  final PaymentMode paymentMode;
  final int firstPayDay;
  final int secondPayDay;
  final Currency currency;

  /// The base salary of the last saved month, or `null` when there is none or
  /// it was in another currency.
  final Money? baseSalary;

  /// The food allowance of the last saved month; `null` like [baseSalary].
  final Money? foodPerDay;

  /// The working hours of the last saved month, or `null` when there is none.
  final int? workingHoursInMonth;

  /// The tax rate in hundredths of a percent (13 % is 1300).
  final int taxRateBasisPoints;

  @override
  List<Object?> get props => [
    paymentMode,
    firstPayDay,
    secondPayDay,
    currency,
    baseSalary,
    foodPerDay,
    workingHoursInMonth,
    taxRateBasisPoints,
  ];
}
