// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_debts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyDebts _$CurrencyDebtsFromJson(Map<String, dynamic> json) =>
    CurrencyDebts(
      currency: CurrencyEnum.fromJson(json['currency'] as String),
      owedToYou: json['owed_to_you'] as Amount,
      youOwe: json['you_owe'] as Amount,
      overdue: (json['overdue'] as List<dynamic>)
          .map((e) => DebtLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      open: (json['open'] as List<dynamic>)
          .map((e) => DebtLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CurrencyDebtsToJson(CurrencyDebts instance) =>
    <String, dynamic>{
      'currency': _$CurrencyEnumEnumMap[instance.currency]!,
      'owed_to_you': instance.owedToYou,
      'you_owe': instance.youOwe,
      'overdue': instance.overdue,
      'open': instance.open,
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
