// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_request.dart';
import 'language_enum.dart';

part 'sign_in_request.g.dart';

/// ``language`` and ``time_zone``: the device the user signs in on decides them.
@JsonSerializable()
class SignInRequest {
  const SignInRequest({
    required this.email,
    required this.password,
    required this.device,
    this.language,
    this.timeZone,
  });

  factory SignInRequest.fromJson(Map<String, Object?> json) =>
      _$SignInRequestFromJson(json);

  /// `en` or `ar`; the app sends `en` when the device language is neither.
  ///
  /// * `en` - English.
  /// * `ar` - Arabic.
  final LanguageEnum? language;

  /// An IANA name such as `Europe/Moscow`. Leave it out when the device cannot read it.
  @JsonKey(name: 'time_zone')
  final String? timeZone;
  final String email;
  final String password;
  final DeviceRequest device;

  Map<String, Object?> toJson() => _$SignInRequestToJson(this);
}
