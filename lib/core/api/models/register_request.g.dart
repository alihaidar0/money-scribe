// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      language: json['language'] == null
          ? null
          : LanguageEnum.fromJson(json['language'] as String),
      timeZone: json['time_zone'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'language': _$LanguageEnumEnumMap[instance.language],
      'time_zone': instance.timeZone,
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
    };

const _$LanguageEnumEnumMap = {
  LanguageEnum.en: 'en',
  LanguageEnum.ar: 'ar',
  LanguageEnum.$unknown: r'$unknown',
};
