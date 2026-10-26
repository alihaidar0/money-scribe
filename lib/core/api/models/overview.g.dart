// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Overview _$OverviewFromJson(Map<String, dynamic> json) => Overview(
  month: json['month'] as String,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  hasData: json['has_data'] as bool,
  currencies: (json['currencies'] as List<dynamic>)
      .map((e) => CurrencyEnum.fromJson(e as String))
      .toList(),
  total: OverviewBlock.fromJson(json['total'] as Map<String, dynamic>),
  firstPart: json['first_part'] == null
      ? null
      : OverviewBlock.fromJson(json['first_part'] as Map<String, dynamic>),
  secondPart: json['second_part'] == null
      ? null
      : OverviewBlock.fromJson(json['second_part'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OverviewToJson(Overview instance) => <String, dynamic>{
  'month': instance.month,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'has_data': instance.hasData,
  'currencies': instance.currencies
      .map((e) => _$CurrencyEnumEnumMap[e]!)
      .toList(),
  'total': instance.total,
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
