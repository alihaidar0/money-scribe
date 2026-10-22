// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'change_password_request.g.dart';

@JsonSerializable()
class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.password,
  });

  factory ChangePasswordRequest.fromJson(Map<String, Object?> json) =>
      _$ChangePasswordRequestFromJson(json);

  /// The password in use now.
  @JsonKey(name: 'current_password')
  final String currentPassword;

  /// The new password, under the same rules as at registration. It must differ from the current one.
  final String password;

  Map<String, Object?> toJson() => _$ChangePasswordRequestToJson(this);
}
