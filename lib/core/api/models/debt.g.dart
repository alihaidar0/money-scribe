// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debt _$DebtFromJson(Map<String, dynamic> json) => Debt(
  id: json['id'] as String,
  direction: DebtDirectionEnum.fromJson(json['direction'] as String),
  person: json['person'] as String,
  amount: json['amount'] as Amount,
  currency: CurrencyEnum.fromJson(json['currency'] as String),
  startDate: DateTime.parse(json['start_date'] as String),
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  note: json['note'] as String,
  repaid: json['repaid'] as Amount,
  remaining: json['remaining'] as Amount,
  status: DebtStatusEnum.fromJson(json['status'] as String),
  repayments: (json['repayments'] as List<dynamic>)
      .map((e) => Repayment.fromJson(e as Map<String, dynamic>))
      .toList(),
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DebtToJson(Debt instance) => <String, dynamic>{
  'id': instance.id,
  'direction': _$DebtDirectionEnumEnumMap[instance.direction]!,
  'person': instance.person,
  'amount': instance.amount,
  'currency': _$CurrencyEnumEnumMap[instance.currency]!,
  'start_date': instance.startDate.toIso8601String(),
  'due_date': instance.dueDate?.toIso8601String(),
  'note': instance.note,
  'repaid': instance.repaid,
  'remaining': instance.remaining,
  'status': _$DebtStatusEnumEnumMap[instance.status]!,
  'repayments': instance.repayments,
  'version': instance.version,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
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

const _$DebtStatusEnumEnumMap = {
  DebtStatusEnum.open: 'open',
  DebtStatusEnum.overdue: 'overdue',
  DebtStatusEnum.settled: 'settled',
  DebtStatusEnum.$unknown: r'$unknown',
};
