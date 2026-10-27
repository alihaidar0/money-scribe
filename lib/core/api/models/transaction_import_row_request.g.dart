// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_import_row_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionImportRowRequest _$TransactionImportRowRequestFromJson(
  Map<String, dynamic> json,
) => TransactionImportRowRequest(
  row: (json['row'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  kind: KindEnum.fromJson(json['kind'] as String),
  amount: json['amount'] as Amount,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  accountName: json['account_name'] as String,
  note: json['note'] as String? ?? '',
  categoryKey: json['category_key'] as String?,
  categoryName: json['category_name'] as String?,
);

Map<String, dynamic> _$TransactionImportRowRequestToJson(
  TransactionImportRowRequest instance,
) => <String, dynamic>{
  'row': instance.row,
  'date': instance.date.toIso8601String(),
  'kind': _$KindEnumEnumMap[instance.kind]!,
  'amount': instance.amount,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'category_key': instance.categoryKey,
  'category_name': instance.categoryName,
  'account_name': instance.accountName,
  'note': instance.note,
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
