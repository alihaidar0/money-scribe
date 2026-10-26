// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityEvent _$SecurityEventFromJson(Map<String, dynamic> json) =>
    SecurityEvent(
      id: json['id'] as String,
      type: SecurityEventTypeEnum.fromJson(json['type'] as String),
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      deviceName: json['device_name'] as String?,
      platform: json['platform'] == null
          ? null
          : PlatformEnum.fromJson(json['platform'] as String),
      appVersion: json['app_version'] as String?,
      signInMethod: json['sign_in_method'] == null
          ? null
          : SignInMethodEnum.fromJson(json['sign_in_method'] as String),
      sessionId: json['session_id'] as String?,
      kinds: (json['kinds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SecurityEventToJson(SecurityEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SecurityEventTypeEnumEnumMap[instance.type]!,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'device_name': instance.deviceName,
      'platform': _$PlatformEnumEnumMap[instance.platform],
      'app_version': instance.appVersion,
      'sign_in_method': _$SignInMethodEnumEnumMap[instance.signInMethod],
      'session_id': instance.sessionId,
      'kinds': instance.kinds,
      'count': instance.count,
    };

const _$SecurityEventTypeEnumEnumMap = {
  SecurityEventTypeEnum.signedIn: 'signed_in',
  SecurityEventTypeEnum.signedOut: 'signed_out',
  SecurityEventTypeEnum.sessionRevoked: 'session_revoked',
  SecurityEventTypeEnum.sessionLimitReached: 'session_limit_reached',
  SecurityEventTypeEnum.passwordChanged: 'password_changed',
  SecurityEventTypeEnum.passwordReset: 'password_reset',
  SecurityEventTypeEnum.emailChanged: 'email_changed',
  SecurityEventTypeEnum.deviceKeyAdded: 'device_key_added',
  SecurityEventTypeEnum.deviceKeyRemoved: 'device_key_removed',
  SecurityEventTypeEnum.tokenReuseDetected: 'token_reuse_detected',
  SecurityEventTypeEnum.dataExported: 'data_exported',
  SecurityEventTypeEnum.dataImported: 'data_imported',
  SecurityEventTypeEnum.$unknown: r'$unknown',
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
