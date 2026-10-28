// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_input_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryInputRequest _$CategoryInputRequestFromJson(
  Map<String, dynamic> json,
) => CategoryInputRequest(
  name: json['name'] as String,
  icon: IconEnum.fromJson(json['icon'] as String),
);

Map<String, dynamic> _$CategoryInputRequestToJson(
  CategoryInputRequest instance,
) => <String, dynamic>{
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
