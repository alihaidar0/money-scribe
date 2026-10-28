// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthReport _$MonthReportFromJson(Map<String, dynamic> json) => MonthReport(
  month: json['month'] as String,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  hasData: json['has_data'] as bool,
  currencies: (json['currencies'] as List<dynamic>)
      .map((e) => CurrencyEnum.fromJson(e as String))
      .toList(),
  incomeTransactions: json['income_transactions'] as Amount,
  purchases: json['purchases'] as Amount,
  categories: (json['categories'] as List<dynamic>)
      .map((e) => CategorySpend.fromJson(e as Map<String, dynamic>))
      .toList(),
  firstPart: json['first_part'] == null
      ? null
      : ReportSlice.fromJson(json['first_part'] as Map<String, dynamic>),
  secondPart: json['second_part'] == null
      ? null
      : ReportSlice.fromJson(json['second_part'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MonthReportToJson(MonthReport instance) =>
    <String, dynamic>{
      'month': instance.month,
      'currency': _$CurrencyEnumEnumMap[instance.currency]!,
      'has_data': instance.hasData,
      'currencies': instance.currencies
          .map((e) => _$CurrencyEnumEnumMap[e]!)
          .toList(),
      'income_transactions': instance.incomeTransactions,
      'purchases': instance.purchases,
      'categories': instance.categories,
      'first_part': instance.firstPart,
      'second_part': instance.secondPart,
    };

const _$CurrencyEnumEnumMap = {
  CurrencyEnum.rub: 'RUB',
  CurrencyEnum.usd: 'USD',
  CurrencyEnum.eur: 'EUR',
  CurrencyEnum.gbp: 'GBP',
  CurrencyEnum.valueTry: 'TRY',
  CurrencyEnum.sar: 'SAR',
  CurrencyEnum.aed: 'AED',
  CurrencyEnum.egp: 'EGP',
  CurrencyEnum.jpy: 'JPY',
  CurrencyEnum.kwd: 'KWD',
  CurrencyEnum.$unknown: r'$unknown',
};
