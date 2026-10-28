// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_create_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtCreateRequest _$DebtCreateRequestFromJson(Map<String, dynamic> json) =>
    DebtCreateRequest(
      direction: DebtDirectionEnum.fromJson(json['direction'] as String),
      person: json['person'] as String,
      amount: json['amount'] as Amount,
      currency: CurrencyEnum.fromJson(json['currency'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      note: json['note'] as String? ?? '',
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
    );

Map<String, dynamic> _$DebtCreateRequestToJson(DebtCreateRequest instance) =>
    <String, dynamic>{
      'direction': _$DebtDirectionEnumEnumMap[instance.direction]!,
      'person': instance.person,
      'amount': instance.amount,
      'currency': _$CurrencyEnumEnumMap[instance.currency]!,
      'start_date': instance.startDate.toIso8601String(),
      'due_date': instance.dueDate?.toIso8601String(),
      'note': instance.note,
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
