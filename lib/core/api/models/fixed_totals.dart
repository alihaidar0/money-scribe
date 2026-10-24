// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'part_totals.dart';

part 'fixed_totals.g.dart';

@JsonSerializable()
class FixedTotals {
  const FixedTotals({required this.first, required this.second});

  factory FixedTotals.fromJson(Map<String, Object?> json) =>
      _$FixedTotalsFromJson(json);

  final PartTotals first;
  final PartTotals? second;

  Map<String, Object?> toJson() => _$FixedTotalsToJson(this);
}
