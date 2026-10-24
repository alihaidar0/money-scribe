// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_request.dart';
import 'language_enum.dart';

part 'device_key_sign_in_request.g.dart';

/// ``language`` and ``time_zone``: the device the user signs in on decides them.
@JsonSerializable()
class DeviceKeySignInRequest {
  const DeviceKeySignInRequest({
    required this.challengeId,
    required this.signature,
    required this.device,
    this.language,
    this.timeZone,
  });

  factory DeviceKeySignInRequest.fromJson(Map<String, Object?> json) =>
      _$DeviceKeySignInRequestFromJson(json);

  /// `en` or `ar`; the app sends `en` when the device language is neither.
  ///
  /// * `en` - English.
  /// * `ar` - Arabic.
  final LanguageEnum? language;

  /// An IANA name such as `Europe/Moscow`. Leave it out when the device cannot read it.
  @JsonKey(name: 'time_zone')
  final String? timeZone;

  /// The `challenge_id` of `auth_device_key_challenge`.
  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// The DER signature, in standard base64 with padding, of the sign-in text.
  final String signature;
  final DeviceRequest device;

  Map<String, Object?> toJson() => _$DeviceKeySignInRequestToJson(this);
}
