// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'resend_code_request.g.dart';

@JsonSerializable()
class ResendCodeRequest {
  const ResendCodeRequest({required this.email});

  factory ResendCodeRequest.fromJson(Map<String, Object?> json) =>
      _$ResendCodeRequestFromJson(json);

  final String email;

  Map<String, Object?> toJson() => _$ResendCodeRequestToJson(this);
}
