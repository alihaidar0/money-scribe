// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'sign_out_request.g.dart';

@JsonSerializable()
class SignOutRequest {
  const SignOutRequest({this.refreshToken});

  factory SignOutRequest.fromJson(Map<String, Object?> json) =>
      _$SignOutRequestFromJson(json);

  /// Lets a device whose access token has expired end its own session without refreshing first.
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  Map<String, Object?> toJson() => _$SignOutRequestToJson(this);
}
