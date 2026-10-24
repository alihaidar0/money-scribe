// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_key_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceKeyList _$DeviceKeyListFromJson(Map<String, dynamic> json) =>
    DeviceKeyList(
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => DeviceKey.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DeviceKeyListToJson(DeviceKeyList instance) =>
    <String, dynamic>{
      'next': instance.next,
      'previous': instance.previous,
      'results': instance.results,
    };
