// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_response.g.dart';

@JsonSerializable()
class RegisterResponse {
  const RegisterResponse({
    required this.codeExpiresIn,
    required this.resendAvailableIn,
    required this.email,
  });

  factory RegisterResponse.fromJson(Map<String, Object?> json) =>
      _$RegisterResponseFromJson(json);

  /// Seconds until the code expires.
  @JsonKey(name: 'code_expires_in')
  final int codeExpiresIn;

  /// Seconds until a new code may be requested.
  @JsonKey(name: 'resend_available_in')
  final int resendAvailableIn;
  final String email;

  Map<String, Object?> toJson() => _$RegisterResponseToJson(this);
}
