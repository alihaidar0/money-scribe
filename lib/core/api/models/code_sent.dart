// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'code_sent.g.dart';

@JsonSerializable()
class CodeSent {
  const CodeSent({
    required this.codeExpiresIn,
    required this.resendAvailableIn,
  });

  factory CodeSent.fromJson(Map<String, Object?> json) =>
      _$CodeSentFromJson(json);

  /// Seconds until the code expires.
  @JsonKey(name: 'code_expires_in')
  final int codeExpiresIn;

  /// Seconds until a new code may be requested.
  @JsonKey(name: 'resend_available_in')
  final int resendAvailableIn;

  Map<String, Object?> toJson() => _$CodeSentToJson(this);
}
