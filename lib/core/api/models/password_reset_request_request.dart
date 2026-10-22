// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'password_reset_request_request.g.dart';

@JsonSerializable()
class PasswordResetRequestRequest {
  const PasswordResetRequestRequest({required this.email});

  factory PasswordResetRequestRequest.fromJson(Map<String, Object?> json) =>
      _$PasswordResetRequestRequestFromJson(json);

  final String email;

  Map<String, Object?> toJson() => _$PasswordResetRequestRequestToJson(this);
}
