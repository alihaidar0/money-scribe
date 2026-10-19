// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceRequest _$DeviceRequestFromJson(Map<String, dynamic> json) =>
    DeviceRequest(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      platform: PlatformEnum.fromJson(json['platform'] as String),
      appVersion: json['app_version'] as String,
      osVersion: json['os_version'] as String? ?? '',
    );

Map<String, dynamic> _$DeviceRequestToJson(DeviceRequest instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'device_name': instance.deviceName,
      'platform': _$PlatformEnumEnumMap[instance.platform]!,
      'os_version': instance.osVersion,
      'app_version': instance.appVersion,
    };

const _$PlatformEnumEnumMap = {
  PlatformEnum.android: 'android',
  PlatformEnum.ios: 'ios',
  PlatformEnum.web: 'web',
  PlatformEnum.$unknown: r'$unknown',
};
