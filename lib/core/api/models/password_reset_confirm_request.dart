// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'password_reset_confirm_request.g.dart';

@JsonSerializable()
class PasswordResetConfirmRequest {
  const PasswordResetConfirmRequest({
    required this.resetToken,
    required this.password,
  });

  factory PasswordResetConfirmRequest.fromJson(Map<String, Object?> json) =>
      _$PasswordResetConfirmRequestFromJson(json);

  /// The `reset_token` that `auth_password_reset_verify` returned. It works once.
  @JsonKey(name: 'reset_token')
  final String resetToken;

  /// The new password, under the same rules as at registration.
  final String password;

  Map<String, Object?> toJson() => _$PasswordResetConfirmRequestToJson(this);
}
