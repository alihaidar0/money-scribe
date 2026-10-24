// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

part 'results.g.dart';

@JsonSerializable()
class Results {
  const Results({
    required this.foodAllowance,
    required this.extraHoursPay,
    required this.incomeBeforeTax,
    required this.tax,
    required this.totalAfterTax,
  });

  factory Results.fromJson(Map<String, Object?> json) =>
      _$ResultsFromJson(json);

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  @JsonKey(name: 'food_allowance')
  final Amount foodAllowance;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  @JsonKey(name: 'extra_hours_pay')
  final Amount extraHoursPay;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  @JsonKey(name: 'income_before_tax')
  final Amount incomeBeforeTax;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount tax;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  @JsonKey(name: 'total_after_tax')
  final Amount totalAfterTax;

  Map<String, Object?> toJson() => _$ResultsToJson(this);
}
