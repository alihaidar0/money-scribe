// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'algorithm_enum.dart';

part 'device_key_register_request.g.dart';

@JsonSerializable()
class DeviceKeyRegisterRequest {
  const DeviceKeyRegisterRequest({
    required this.currentPassword,
    required this.publicKey,
    required this.algorithm,
    required this.challengeId,
    required this.signature,
    this.attestationChain,
  });

  factory DeviceKeyRegisterRequest.fromJson(Map<String, Object?> json) =>
      _$DeviceKeyRegisterRequestFromJson(json);

  /// The password in use now.
  @JsonKey(name: 'current_password')
  final String currentPassword;

  /// The public key of the device: P-256, SPKI DER in standard base64 with padding.
  @JsonKey(name: 'public_key')
  final String publicKey;

  /// Only `ES256` (ECDSA on P-256 with SHA-256).
  ///
  /// * `ES256` - ES256.
  final AlgorithmEnum algorithm;

  /// The `challenge_id` of `auth_device_key_challenge`.
  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// The DER signature, in standard base64 with padding, of the registration text.
  final String signature;

  /// Android only: the certificate chain of the key attestation, leaf first, each certificate DER in standard base64. Required for an Android session; `null` or left out on iOS.
  @JsonKey(name: 'attestation_chain')
  final List<String>? attestationChain;

  Map<String, Object?> toJson() => _$DeviceKeyRegisterRequestToJson(this);
}
