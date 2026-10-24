// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceKey _$DeviceKeyFromJson(Map<String, dynamic> json) => DeviceKey(
  id: json['id'] as String,
  deviceId: json['device_id'] as String,
  deviceName: json['device_name'] as String,
  platform: PlatformEnum.fromJson(json['platform'] as String),
  attested: json['attested'] as bool,
  isCurrent: json['is_current'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  lastUsedAt: json['last_used_at'] == null
      ? null
      : DateTime.parse(json['last_used_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$DeviceKeyToJson(DeviceKey instance) => <String, dynamic>{
  'id': instance.id,
  'device_id': instance.deviceId,
  'device_name': instance.deviceName,
  'platform': _$PlatformEnumEnumMap[instance.platform]!,
  'attested': instance.attested,
  'is_current': instance.isCurrent,
  'created_at': instance.createdAt.toIso8601String(),
  'last_used_at': instance.lastUsedAt?.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
};

const _$PlatformEnumEnumMap = {
  PlatformEnum.android: 'android',
  PlatformEnum.ios: 'ios',
  PlatformEnum.web: 'web',
  PlatformEnum.$unknown: r'$unknown',
};
