// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_transaction_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedTransactionUpdateRequest _$PatchedTransactionUpdateRequestFromJson(
  Map<String, dynamic> json,
) => PatchedTransactionUpdateRequest(
  partValue: json['part'] == null
      ? null
      : PartEnum.fromJson(json['part'] as String),
  partMonth: json['part_month'] as String?,
  kind: KindEnum.fromJson(json['kind'] as String),
  amount: json['amount'] as Amount,
  date: DateTime.parse(json['date'] as String),
  categoryId: json['category_id'] as String,
  accountId: json['account_id'] as String,
  note: json['note'] as String,
);

Map<String, dynamic> _$PatchedTransactionUpdateRequestToJson(
  PatchedTransactionUpdateRequest instance,
) => <String, dynamic>{
  'part': _$PartEnumEnumMap[instance.partValue],
  'part_month': instance.partMonth,
  'kind': _$KindEnumEnumMap[instance.kind]!,
  'amount': instance.amount,
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
