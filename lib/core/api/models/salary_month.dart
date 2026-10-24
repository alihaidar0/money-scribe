// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'balances.dart';
import 'currency_enum.dart';
import 'fixed_item.dart';
import 'fixed_totals.dart';
import 'payment.dart';
import 'payment_mode_enum.dart';
import 'results.dart';

part 'salary_month.g.dart';

/// A saved month with its results, its fixed items, their totals and the balances. Read only.
@JsonSerializable()
class SalaryMonth {
  const SalaryMonth({
    required this.id,
    required this.month,
    required this.currency,
    required this.baseSalary,
    required this.foodPerDay,
    required this.workingDaysInMonth,
    required this.workingHoursInMonth,
    required this.extraHoursHundredths,
    required this.taxRateBasisPoints,
    required this.paymentMode,
    required this.workingDaysFirstHalf,
    required this.firstPayDay,
    required this.secondPayDay,
    required this.calculationVersion,
    required this.results,
    required this.payments,
    required this.fixedItems,
    required this.fixedTotals,
    required this.balances,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalaryMonth.fromJson(Map<String, Object?> json) =>
      _$SalaryMonthFromJson(json);

  final String id;

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
  @JsonKey(name: 'extra_hours_hundredths')
  final int extraHoursHundredths;
  @JsonKey(name: 'tax_rate_basis_points')
  final int taxRateBasisPoints;
  @JsonKey(name: 'payment_mode')
  final PaymentModeEnum paymentMode;
  @JsonKey(name: 'working_days_first_half')
  final int? workingDaysFirstHalf;
  @JsonKey(name: 'first_pay_day')
  final int firstPayDay;
  @JsonKey(name: 'second_pay_day')
  final int secondPayDay;

  /// The version of the formulas the results were calculated under.
  @JsonKey(name: 'calculation_version')
  final int calculationVersion;
  final Results results;

  /// One entry, `first`, or two.
  final List<Payment> payments;
  @JsonKey(name: 'fixed_items')
  final List<FixedItem> fixedItems;
  @JsonKey(name: 'fixed_totals')
  final FixedTotals fixedTotals;
  final Balances balances;
  final int version;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$SalaryMonthToJson(this);
}
