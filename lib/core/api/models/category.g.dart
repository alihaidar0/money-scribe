// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String,
  kind: CategoryKindEnum.fromJson(json['kind'] as String),
  isCustom: json['is_custom'] as bool,
  key: json['key'] as String?,
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon': instance.icon,
  'kind': _$CategoryKindEnumEnumMap[instance.kind]!,
  'is_custom': instance.isCustom,
  'key': instance.key,
  'version': instance.version,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$CategoryKindEnumEnumMap = {
  CategoryKindEnum.expense: 'expense',
  CategoryKindEnum.income: 'income',
  CategoryKindEnum.both: 'both',
  CategoryKindEnum.$unknown: r'$unknown',
};
