// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_fixed_item_input_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedFixedItemInputRequest _$PatchedFixedItemInputRequestFromJson(
  Map<String, dynamic> json,
) => PatchedFixedItemInputRequest(
  name: json['name'] as String,
  amount: json['amount'] as Amount,
  kind: KindEnum.fromJson(json['kind'] as String),
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  partValue: json['part'] == null
      ? PartEnum.first
      : PartEnum.fromJson(json['part'] as String),
);

Map<String, dynamic> _$PatchedFixedItemInputRequestToJson(
  PatchedFixedItemInputRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'amount': instance.amount,
  'kind': _$KindEnumEnumMap[instance.kind]!,
  'part': _$PartEnumEnumMap[instance.partValue]!,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
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
