// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_import_row_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryImportRowRequest _$CategoryImportRowRequestFromJson(
  Map<String, dynamic> json,
) => CategoryImportRowRequest(
  row: (json['row'] as num).toInt(),
  name: json['name'] as String,
  icon: IconEnum.fromJson(json['icon'] as String),
);

Map<String, dynamic> _$CategoryImportRowRequestToJson(
  CategoryImportRowRequest instance,
) => <String, dynamic>{
  'row': instance.row,
  'name': instance.name,
  'icon': _$IconEnumEnumMap[instance.icon]!,
};

const _$IconEnumEnumMap = {
  IconEnum.gifts: 'gifts',
  IconEnum.health: 'health',
  IconEnum.entertainment: 'entertainment',
  IconEnum.shopping: 'shopping',
  IconEnum.education: 'education',
  IconEnum.travel: 'travel',
  IconEnum.subscriptions: 'subscriptions',
  IconEnum.other: 'other',
  IconEnum.$unknown: r'$unknown',
};
