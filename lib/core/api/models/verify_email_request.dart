// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_request.dart';
import 'language_enum.dart';

part 'verify_email_request.g.dart';

/// ``language`` and ``time_zone``: the device the user signs in on decides them.
@JsonSerializable()
class VerifyEmailRequest {
  const VerifyEmailRequest({
    required this.email,
    required this.code,
    required this.device,
    this.language,
    this.timeZone,
  });

  factory VerifyEmailRequest.fromJson(Map<String, Object?> json) =>
      _$VerifyEmailRequestFromJson(json);

  /// `en` or `ar`; the app sends `en` when the device language is neither.
  ///
  /// * `en` - English.
  /// * `ar` - Arabic.
  final LanguageEnum? language;

  /// An IANA name such as `Europe/Moscow`. Leave it out when the device cannot read it.
  @JsonKey(name: 'time_zone')
  final String? timeZone;
  final String email;

  /// The 6-digit code from the email.
  final String code;
  final DeviceRequest device;

  Map<String, Object?> toJson() => _$VerifyEmailRequestToJson(this);
}
