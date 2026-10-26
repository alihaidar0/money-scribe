// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_total.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyTotal _$CurrencyTotalFromJson(Map<String, dynamic> json) =>
    CurrencyTotal(
      currency: CurrencyEnum.fromJson(json['currency'] as String),
      total: json['total'] as SignedAmount,
    );

Map<String, dynamic> _$CurrencyTotalToJson(CurrencyTotal instance) =>
    <String, dynamic>{
      'currency': _$CurrencyEnumEnumMap[instance.currency]!,
      'total': instance.total,
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
