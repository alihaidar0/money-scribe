// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'import_fixed_item_request.dart';
import 'payment_mode_enum.dart';

part 'salary_month_import_row_request.g.dart';

/// A salary month of the file. `extra_hours` and `tax_rate` are the readable forms of the salary month API's.
/// `extra_hours_hundredths` and `tax_rate_basis_points`.
@JsonSerializable()
class SalaryMonthImportRowRequest {
  const SalaryMonthImportRowRequest({
    required this.row,
    required this.month,
    required this.currency,
    required this.baseSalary,
    required this.foodPerDay,
    required this.workingDaysInMonth,
    required this.workingHoursInMonth,
    required this.extraHours,
    required this.taxRate,
    required this.paymentMode,
    required this.firstPayDay,
    required this.secondPayDay,
    this.workingDaysFirstHalf,
    this.fixedItems,
  });

  factory SalaryMonthImportRowRequest.fromJson(Map<String, Object?> json) =>
      _$SalaryMonthImportRowRequestFromJson(json);

  /// The line in the file: a positive whole number, unique in the call.
  final int row;

  /// `YYYY-MM`.
  final String month;

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

  /// Hours with exactly two decimals, `0.00` to `744.00` (`7.50` is seven and a half hours).
  @JsonKey(name: 'extra_hours')
  final String extraHours;

  /// A percent with exactly two decimals, `0.00` to `100.00`.
  @JsonKey(name: 'tax_rate')
  final String taxRate;
  @JsonKey(name: 'payment_mode')
  final PaymentModeEnum paymentMode;

  /// Required with two payments, up to `working_days_in_month`; ignored with one.
  @JsonKey(name: 'working_days_first_half')
  final int? workingDaysFirstHalf;
  @JsonKey(name: 'first_pay_day')
  final int firstPayDay;
  @JsonKey(name: 'second_pay_day')
  final int secondPayDay;

  /// `[]` or a left out cell when there are none.
  @JsonKey(name: 'fixed_items')
  final List<ImportFixedItemRequest>? fixedItems;

  Map<String, Object?> toJson() => _$SalaryMonthImportRowRequestToJson(this);
}
