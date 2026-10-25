// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignInRequest _$SignInRequestFromJson(Map<String, dynamic> json) =>
    SignInRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      device: DeviceRequest.fromJson(json['device'] as Map<String, dynamic>),
      language: json['language'] == null
          ? null
          : LanguageEnum.fromJson(json['language'] as String),
      timeZone: json['time_zone'] as String?,
      captchaToken: json['captcha_token'] as String?,
    );

Map<String, dynamic> _$SignInRequestToJson(SignInRequest instance) =>
    <String, dynamic>{
      'language': _$LanguageEnumEnumMap[instance.language],
      'time_zone': instance.timeZone,
      'email': instance.email,
      'password': instance.password,
      'captcha_token': instance.captchaToken,
      'device': instance.device,
    };

const _$LanguageEnumEnumMap = {
  LanguageEnum.en: 'en',
  LanguageEnum.ar: 'ar',
  LanguageEnum.$unknown: r'$unknown',
};
