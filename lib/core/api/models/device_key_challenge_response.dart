// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'device_key_challenge_response.g.dart';

@JsonSerializable()
class DeviceKeyChallengeResponse {
  const DeviceKeyChallengeResponse({
    required this.challengeId,
    required this.challenge,
    required this.expiresIn,
  });

  factory DeviceKeyChallengeResponse.fromJson(Map<String, Object?> json) =>
      _$DeviceKeyChallengeResponseFromJson(json);

  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// 32 random bytes in base64url without padding. Sign it exactly as sent.
  final String challenge;

  /// Seconds the challenge lives (120). It works once.
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  Map<String, Object?> toJson() => _$DeviceKeyChallengeResponseToJson(this);
}
