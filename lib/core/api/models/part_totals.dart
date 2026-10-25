// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

part 'part_totals.g.dart';

@JsonSerializable()
class PartTotals {
  const PartTotals({required this.income, required this.expense});

  factory PartTotals.fromJson(Map<String, Object?> json) =>
      _$PartTotalsFromJson(json);

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount income;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount expense;

  Map<String, Object?> toJson() => _$PartTotalsToJson(this);
}
