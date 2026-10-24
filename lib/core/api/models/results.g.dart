// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Results _$ResultsFromJson(Map<String, dynamic> json) => Results(
  foodAllowance: json['food_allowance'] as Amount,
  extraHoursPay: json['extra_hours_pay'] as Amount,
  incomeBeforeTax: json['income_before_tax'] as Amount,
  tax: json['tax'] as Amount,
  totalAfterTax: json['total_after_tax'] as Amount,
);

Map<String, dynamic> _$ResultsToJson(Results instance) => <String, dynamic>{
  'food_allowance': instance.foodAllowance,
  'extra_hours_pay': instance.extraHoursPay,
  'income_before_tax': instance.incomeBeforeTax,
  'tax': instance.tax,
  'total_after_tax': instance.totalAfterTax,
};
