// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FixedItem _$FixedItemFromJson(Map<String, dynamic> json) => FixedItem(
  id: json['id'] as String,
  name: json['name'] as String,
  amount: json['amount'] as Amount,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  kind: KindEnum.fromJson(json['kind'] as String),
  partValue: PartEnum.fromJson(json['part'] as String),
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$FixedItemToJson(FixedItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'amount': instance.amount,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'kind': _$KindEnumEnumMap[instance.kind]!,
  'part': _$PartEnumEnumMap[instance.partValue]!,
  'version': instance.version,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
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

const _$KindEnumEnumMap = {
  KindEnum.income: 'income',
  KindEnum.expense: 'expense',
  KindEnum.$unknown: r'$unknown',
};

const _$PartEnumEnumMap = {
  PartEnum.first: 'first',
  PartEnum.second: 'second',
  PartEnum.$unknown: r'$unknown',
};
