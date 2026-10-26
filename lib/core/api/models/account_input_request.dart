// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'account_kind_enum.dart';

part 'account_input_request.g.dart';

/// An account to add or to change. Anything else (`id`, `version`, ...) is `400 read_only`.
@JsonSerializable()
class AccountInputRequest {
  const AccountInputRequest({required this.name, required this.kind});

  factory AccountInputRequest.fromJson(Map<String, Object?> json) =>
      _$AccountInputRequestFromJson(json);

  /// 1 to 30 characters, trimmed. Unique per person, in any case: `400 name_taken`.
  final String name;
  final AccountKindEnum kind;

  Map<String, Object?> toJson() => _$AccountInputRequestToJson(this);
}
