// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_slice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportSlice _$ReportSliceFromJson(Map<String, dynamic> json) => ReportSlice(
  incomeTransactions: json['income_transactions'] as Amount,
  purchases: json['purchases'] as Amount,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => CategorySpend.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReportSliceToJson(ReportSlice instance) =>
    <String, dynamic>{
      'income_transactions': instance.incomeTransactions,
      'purchases': instance.purchases,
      'categories': instance.categories,
    };
