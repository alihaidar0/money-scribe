// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'payment_mode_enum.dart';

part 'salary_month_input_request.g.dart';

/// The inputs of a month; the server calculates the rest and the client never sends a result.
@JsonSerializable()
class SalaryMonthInputRequest {
  const SalaryMonthInputRequest({
    required this.currency,
    required this.baseSalary,
    required this.foodPerDay,
    required this.workingDaysInMonth,
    required this.workingHoursInMonth,
    required this.extraHoursHundredths,
    required this.taxRateBasisPoints,
    required this.paymentMode,
    required this.firstPayDay,
    required this.secondPayDay,
    this.workingDaysFirstHalf,
  });

  factory SalaryMonthInputRequest.fromJson(Map<String, Object?> json) =>
      _$SalaryMonthInputRequestFromJson(json);

  /// The ISO 4217 code of the currency.
  ///
  /// * `RUB` - RUB.
  /// * `USD` - USD.
  /// * `EUR` - EUR.
  /// * `GBP` - GBP.
  /// * `TRY` - TRY.
  /// * `SAR` - SAR.
  /// * `AED` - AED.
  /// * `EGP` - EGP.
  /// * `JPY` - JPY.
  /// * `KWD` - KWD.
  final CurrencyEnum currency;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  @JsonKey(name: 'base_salary')
  final Amount baseSalary;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  @JsonKey(name: 'food_per_day')
  final Amount foodPerDay;
  @JsonKey(name: 'working_days_in_month')
  final int workingDaysInMonth;
  @JsonKey(name: 'working_hours_in_month')
  final int workingHoursInMonth;

  /// Hours in hundredths: 750 is 7.5 hours.
  @JsonKey(name: 'extra_hours_hundredths')
  final int extraHoursHundredths;

  /// 1300 is 13%.
  @JsonKey(name: 'tax_rate_basis_points')
  final int taxRateBasisPoints;
  @JsonKey(name: 'payment_mode')
  final PaymentModeEnum paymentMode;

  /// The working days of the first half of the month, up to `working_days_in_month`. Required with two payments; with one payment it is ignored and stored as `null`.
  @JsonKey(name: 'working_days_first_half')
  final int? workingDaysFirstHalf;
  @JsonKey(name: 'first_pay_day')
  final int firstPayDay;
  @JsonKey(name: 'second_pay_day')
  final int secondPayDay;

  Map<String, Object?> toJson() => _$SalaryMonthInputRequestToJson(this);
}
