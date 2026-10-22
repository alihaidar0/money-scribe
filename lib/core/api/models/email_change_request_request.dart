// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'email_change_request_request.g.dart';

@JsonSerializable()
class EmailChangeRequestRequest {
  const EmailChangeRequestRequest({
    required this.email,
    required this.currentPassword,
  });

  factory EmailChangeRequestRequest.fromJson(Map<String, Object?> json) =>
      _$EmailChangeRequestRequestFromJson(json);

  /// The new address.
  final String email;

  /// The password in use now.
  @JsonKey(name: 'current_password')
  final String currentPassword;

  Map<String, Object?> toJson() => _$EmailChangeRequestRequestToJson(this);
}
