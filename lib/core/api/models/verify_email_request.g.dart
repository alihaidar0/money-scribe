// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_email_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyEmailRequest _$VerifyEmailRequestFromJson(Map<String, dynamic> json) =>
    VerifyEmailRequest(
      email: json['email'] as String,
      code: json['code'] as String,
      device: DeviceRequest.fromJson(json['device'] as Map<String, dynamic>),
      language: json['language'] == null
          ? null
          : LanguageEnum.fromJson(json['language'] as String),
      timeZone: json['time_zone'] as String?,
    );

Map<String, dynamic> _$VerifyEmailRequestToJson(VerifyEmailRequest instance) =>
    <String, dynamic>{
      'language': _$LanguageEnumEnumMap[instance.language],
      'time_zone': instance.timeZone,
      'email': instance.email,
      'code': instance.code,
      'device': instance.device,
    };

const _$LanguageEnumEnumMap = {
  LanguageEnum.en: 'en',
  LanguageEnum.ar: 'ar',
  LanguageEnum.$unknown: r'$unknown',
};
