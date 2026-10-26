// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency_total.dart';

part 'day_total.g.dart';

@JsonSerializable()
class DayTotal {
  const DayTotal({required this.date, required this.totals});

  factory DayTotal.fromJson(Map<String, Object?> json) =>
      _$DayTotalFromJson(json);

  final DateTime date;
  final List<CurrencyTotal> totals;

  Map<String, Object?> toJson() => _$DayTotalToJson(this);
}
