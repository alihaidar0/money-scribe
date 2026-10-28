// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debts_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtsReport _$DebtsReportFromJson(Map<String, dynamic> json) => DebtsReport(
  hasData: json['has_data'] as bool,
  byCurrency: (json['by_currency'] as List<dynamic>)
      .map((e) => CurrencyDebts.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DebtsReportToJson(DebtsReport instance) =>
    <String, dynamic>{
      'has_data': instance.hasData,
      'by_currency': instance.byCurrency,
    };
