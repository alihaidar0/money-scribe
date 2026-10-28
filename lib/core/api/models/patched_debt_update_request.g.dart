// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_debt_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedDebtUpdateRequest _$PatchedDebtUpdateRequestFromJson(
  Map<String, dynamic> json,
) => PatchedDebtUpdateRequest(
  direction: DebtDirectionEnum.fromJson(json['direction'] as String),
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
  'direction': _$DebtDirectionEnumEnumMap[instance.direction]!,
  'person': instance.person,
  'amount': instance.amount,
  'start_date': instance.startDate.toIso8601String(),
  'due_date': instance.dueDate?.toIso8601String(),
  'note': instance.note,
};

const _$DebtDirectionEnumEnumMap = {
  DebtDirectionEnum.lent: 'lent',
  DebtDirectionEnum.borrowed: 'borrowed',
  DebtDirectionEnum.$unknown: r'$unknown',
};
