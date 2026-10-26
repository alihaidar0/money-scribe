// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
  id: json['id'] as String,
  deviceId: json['device_id'] as String,
  deviceName: json['device_name'] as String,
  platform: PlatformEnum.fromJson(json['platform'] as String),
  osVersion: json['os_version'] as String,
  appVersion: json['app_version'] as String,
  signedInAt: DateTime.parse(json['signed_in_at'] as String),
  lastActiveAt: DateTime.parse(json['last_active_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  isCurrent: json['is_current'] as bool,
  signInMethod: SignInMethodEnum.fromJson(json['sign_in_method'] as String),
  network: json['network'] as String?,
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
  endReason: json['end_reason'] as String?,
);

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
  'id': instance.id,
  'device_id': instance.deviceId,
  'device_name': instance.deviceName,
  'platform': _$PlatformEnumEnumMap[instance.platform]!,
  'os_version': instance.osVersion,
  'app_version': instance.appVersion,
  'signed_in_at': instance.signedInAt.toIso8601String(),
  'last_active_at': instance.lastActiveAt.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
  'is_current': instance.isCurrent,
  'sign_in_method': _$SignInMethodEnumEnumMap[instance.signInMethod]!,
  'network': instance.network,
  'ended_at': instance.endedAt?.toIso8601String(),
  'end_reason': instance.endReason,
};

const _$PlatformEnumEnumMap = {
  PlatformEnum.android: 'android',
  PlatformEnum.ios: 'ios',
  PlatformEnum.web: 'web',
  PlatformEnum.$unknown: r'$unknown',
};

const _$SignInMethodEnumEnumMap = {
  SignInMethodEnum.password: 'password',
  SignInMethodEnum.emailCode: 'email_code',
  SignInMethodEnum.deviceKey: 'device_key',
  SignInMethodEnum.$unknown: r'$unknown',
};
