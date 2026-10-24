// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_key_sign_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceKeySignInRequest _$DeviceKeySignInRequestFromJson(
  Map<String, dynamic> json,
) => DeviceKeySignInRequest(
  challengeId: json['challenge_id'] as String,
  signature: json['signature'] as String,
  device: DeviceRequest.fromJson(json['device'] as Map<String, dynamic>),
  language: json['language'] == null
      ? null
      : LanguageEnum.fromJson(json['language'] as String),
  timeZone: json['time_zone'] as String?,
);

Map<String, dynamic> _$DeviceKeySignInRequestToJson(
  DeviceKeySignInRequest instance,
) => <String, dynamic>{
  'language': _$LanguageEnumEnumMap[instance.language],
  'time_zone': instance.timeZone,
  'challenge_id': instance.challengeId,
  'signature': instance.signature,
  'device': instance.device,
};

const _$LanguageEnumEnumMap = {
  LanguageEnum.en: 'en',
  LanguageEnum.ar: 'ar',
  LanguageEnum.$unknown: r'$unknown',
};
