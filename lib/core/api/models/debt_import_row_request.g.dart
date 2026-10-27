// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_import_row_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtImportRowRequest _$DebtImportRowRequestFromJson(
  Map<String, dynamic> json,
) => DebtImportRowRequest(
  row: (json['row'] as num).toInt(),
  direction: DebtDirectionEnum.fromJson(json['direction'] as String),
  person: json['person'] as String,
  amount: json['amount'] as Amount,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  startDate: DateTime.parse(json['start_date'] as String),
  note: json['note'] as String? ?? '',
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  repayments: (json['repayments'] as List<dynamic>?)
      ?.map((e) => ImportRepaymentRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DebtImportRowRequestToJson(
  DebtImportRowRequest instance,
) => <String, dynamic>{
  'row': instance.row,
  'direction': _$DebtDirectionEnumEnumMap[instance.direction]!,
  'person': instance.person,
  'amount': instance.amount,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'start_date': instance.startDate.toIso8601String(),
  'due_date': instance.dueDate?.toIso8601String(),
  'note': instance.note,
  'repayments': instance.repayments,
};

const _$DebtDirectionEnumEnumMap = {
  DebtDirectionEnum.lent: 'lent',
  DebtDirectionEnum.borrowed: 'borrowed',
  DebtDirectionEnum.$unknown: r'$unknown',
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
