// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_summary.dart';

part 'signed_in_response.g.dart';

@JsonSerializable()
class SignedInResponse {
  const SignedInResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    this.refreshToken,
  });

  factory SignedInResponse.fromJson(Map<String, Object?> json) =>
      _$SignedInResponseFromJson(json);

  /// Send it as `Authorization: Bearer`.
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// Single-use. Absent when the web form of the tokens carries it in a cookie.
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  /// Always `Bearer`.
  @JsonKey(name: 'token_type')
  final String tokenType;

  /// Seconds the access token lives (600).
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  final UserSummary user;

  Map<String, Object?> toJson() => _$SignedInResponseToJson(this);
}
