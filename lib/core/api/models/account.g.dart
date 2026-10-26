// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: json['id'] as String,
  name: json['name'] as String,
  kind: AccountKindEnum.fromJson(json['kind'] as String),
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'kind': _$AccountKindEnumEnumMap[instance.kind]!,
  'version': instance.version,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$AccountKindEnumEnumMap = {
  AccountKindEnum.card: 'card',
  AccountKindEnum.cash: 'cash',
  AccountKindEnum.other: 'other',
  AccountKindEnum.$unknown: r'$unknown',
};
