// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'password_reset_verify_request.g.dart';

@JsonSerializable()
class PasswordResetVerifyRequest {
  const PasswordResetVerifyRequest({required this.email, required this.code});

  factory PasswordResetVerifyRequest.fromJson(Map<String, Object?> json) =>
      _$PasswordResetVerifyRequestFromJson(json);

  final String email;

  /// The 6-digit code from the email.
  final String code;

  Map<String, Object?> toJson() => _$PasswordResetVerifyRequestToJson(this);
}
