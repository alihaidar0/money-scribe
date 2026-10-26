// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_debt_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedDebtUpdateRequest _$PatchedDebtUpdateRequestFromJson(
  Map<String, dynamic> json,
) => PatchedDebtUpdateRequest(
  person: json['person'] as String,
  amount: json['amount'] as Amount,
  startDate: DateTime.parse(json['start_date'] as String),
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
  note: json['note'] as String,
);

Map<String, dynamic> _$PatchedDebtUpdateRequestToJson(
  PatchedDebtUpdateRequest instance,
) => <String, dynamic>{
  'person': instance.person,
  'amount': instance.amount,
  'start_date': instance.startDate.toIso8601String(),
  'due_date': instance.dueDate?.toIso8601String(),
  'note': instance.note,
};
