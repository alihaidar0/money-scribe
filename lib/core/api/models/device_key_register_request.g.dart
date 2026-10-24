// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_key_register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceKeyRegisterRequest _$DeviceKeyRegisterRequestFromJson(
  Map<String, dynamic> json,
) => DeviceKeyRegisterRequest(
  currentPassword: json['current_password'] as String,
  publicKey: json['public_key'] as String,
  algorithm: AlgorithmEnum.fromJson(json['algorithm'] as String),
  challengeId: json['challenge_id'] as String,
  signature: json['signature'] as String,
  attestationChain: (json['attestation_chain'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$DeviceKeyRegisterRequestToJson(
  DeviceKeyRegisterRequest instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'public_key': instance.publicKey,
  'algorithm': _$AlgorithmEnumEnumMap[instance.algorithm]!,
  'challenge_id': instance.challengeId,
  'signature': instance.signature,
  'attestation_chain': instance.attestationChain,
};

const _$AlgorithmEnumEnumMap = {
  AlgorithmEnum.es256: 'ES256',
  AlgorithmEnum.$unknown: r'$unknown',
};
