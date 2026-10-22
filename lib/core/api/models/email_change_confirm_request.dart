// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'email_change_confirm_request.g.dart';

@JsonSerializable()
class EmailChangeConfirmRequest {
  const EmailChangeConfirmRequest({required this.code});

  factory EmailChangeConfirmRequest.fromJson(Map<String, Object?> json) =>
      _$EmailChangeConfirmRequestFromJson(json);

  /// The 6-digit code mailed to the new address.
  final String code;

  Map<String, Object?> toJson() => _$EmailChangeConfirmRequestToJson(this);
}
