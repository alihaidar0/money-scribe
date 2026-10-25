// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reset_token_response.g.dart';

@JsonSerializable()
class ResetTokenResponse {
  const ResetTokenResponse({required this.resetToken, required this.expiresIn});

  factory ResetTokenResponse.fromJson(Map<String, Object?> json) =>
      _$ResetTokenResponseFromJson(json);

  /// Single use. Send it, with the new password, to `auth_password_reset_confirm`.
  @JsonKey(name: 'reset_token')
  final String resetToken;

  /// Seconds until the reset token expires (600).
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  Map<String, Object?> toJson() => _$ResetTokenResponseToJson(this);
}
