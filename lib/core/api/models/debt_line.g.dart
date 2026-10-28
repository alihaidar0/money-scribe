// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtLine _$DebtLineFromJson(Map<String, dynamic> json) => DebtLine(
  id: json['id'] as String,
  person: json['person'] as String,
  direction: DebtDirectionEnum.fromJson(json['direction'] as String),
  remaining: json['remaining'] as Amount,
  status: DebtStatusEnum.fromJson(json['status'] as String),
  dueDate: json['due_date'] == null
      ? null
      : DateTime.parse(json['due_date'] as String),
);

Map<String, dynamic> _$DebtLineToJson(DebtLine instance) => <String, dynamic>{
  'id': instance.id,
  'person': instance.person,
  'direction': _$DebtDirectionEnumEnumMap[instance.direction]!,
  'remaining': instance.remaining,
  'status': _$DebtStatusEnumEnumMap[instance.status]!,
  'due_date': instance.dueDate?.toIso8601String(),
};

const _$DebtDirectionEnumEnumMap = {
  DebtDirectionEnum.lent: 'lent',
  DebtDirectionEnum.borrowed: 'borrowed',
  DebtDirectionEnum.$unknown: r'$unknown',
};

const _$DebtStatusEnumEnumMap = {
  DebtStatusEnum.open: 'open',
  DebtStatusEnum.overdue: 'overdue',
  DebtStatusEnum.settled: 'settled',
  DebtStatusEnum.$unknown: r'$unknown',
};
