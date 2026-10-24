// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_key_challenge_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceKeyChallengeResponse _$DeviceKeyChallengeResponseFromJson(
  Map<String, dynamic> json,
) => DeviceKeyChallengeResponse(
  challengeId: json['challenge_id'] as String,
  challenge: json['challenge'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$DeviceKeyChallengeResponseToJson(
  DeviceKeyChallengeResponse instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'challenge': instance.challenge,
  'expires_in': instance.expiresIn,
};
