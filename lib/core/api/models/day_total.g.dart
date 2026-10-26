// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_total.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayTotal _$DayTotalFromJson(Map<String, dynamic> json) => DayTotal(
  date: DateTime.parse(json['date'] as String),
  totals: (json['totals'] as List<dynamic>)
      .map((e) => CurrencyTotal.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DayTotalToJson(DayTotal instance) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'totals': instance.totals,
};
