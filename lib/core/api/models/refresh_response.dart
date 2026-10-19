// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'refresh_response.g.dart';

@JsonSerializable()
class RefreshResponse {
  const RefreshResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
  });

  factory RefreshResponse.fromJson(Map<String, Object?> json) =>
      _$RefreshResponseFromJson(json);

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

  Map<String, Object?> toJson() => _$RefreshResponseToJson(this);
}
