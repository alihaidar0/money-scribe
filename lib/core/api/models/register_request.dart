// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'language_enum.dart';

part 'register_request.g.dart';

/// ``language`` and ``time_zone``: the device the user signs in on decides them.
@JsonSerializable()
class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.language,
    this.timeZone,
  });

  factory RegisterRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterRequestFromJson(json);

  /// `en` or `ar`; the app sends `en` when the device language is neither.
  ///
  /// * `en` - English.
  /// * `ar` - Arabic.
  final LanguageEnum? language;

  /// An IANA name such as `Europe/Moscow`. Leave it out when the device cannot read it.
  @JsonKey(name: 'time_zone')
  final String? timeZone;
  final String name;
  final String email;

  /// At least 15 characters; no other composition rule. It must not resemble the name or email, be a very common password or appear in a known data breach.
  final String password;

  Map<String, Object?> toJson() => _$RegisterRequestToJson(this);
}
