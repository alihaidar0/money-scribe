// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_totals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FixedTotals _$FixedTotalsFromJson(Map<String, dynamic> json) => FixedTotals(
  first: PartTotals.fromJson(json['first'] as Map<String, dynamic>),
  second: json['second'] == null
      ? null
      : PartTotals.fromJson(json['second'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FixedTotalsToJson(FixedTotals instance) =>
    <String, dynamic>{'first': instance.first, 'second': instance.second};
