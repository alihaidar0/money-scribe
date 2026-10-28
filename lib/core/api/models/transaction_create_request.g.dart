// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionCreateRequest _$TransactionCreateRequestFromJson(
  Map<String, dynamic> json,
) => TransactionCreateRequest(
  kind: KindEnum.fromJson(json['kind'] as String),
  amount: json['amount'] as Amount,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  date: DateTime.parse(json['date'] as String),
  categoryId: json['category_id'] as String,
  accountId: json['account_id'] as String,
  note: json['note'] as String? ?? '',
  partValue: json['part'] == null
      ? null
      : PartEnum.fromJson(json['part'] as String),
  partMonth: json['part_month'] as String?,
);

Map<String, dynamic> _$TransactionCreateRequestToJson(
  TransactionCreateRequest instance,
) => <String, dynamic>{
  'part': _$PartEnumEnumMap[instance.partValue],
  'part_month': instance.partMonth,
  'kind': _$KindEnumEnumMap[instance.kind]!,
  'amount': instance.amount,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'date': instance.date.toIso8601String(),
  'category_id': instance.categoryId,
  'account_id': instance.accountId,
  'note': instance.note,
};

const _$PartEnumEnumMap = {
  PartEnum.first: 'first',
  PartEnum.second: 'second',
  PartEnum.$unknown: r'$unknown',
};

const _$KindEnumEnumMap = {
  KindEnum.income: 'income',
  KindEnum.expense: 'expense',
  KindEnum.$unknown: r'$unknown',
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
