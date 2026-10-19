// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_summary.g.dart';

@JsonSerializable()
class UserSummary {
  const UserSummary({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserSummary.fromJson(Map<String, Object?> json) =>
      _$UserSummaryFromJson(json);

  final String id;
  final String name;
  final String email;

  Map<String, Object?> toJson() => _$UserSummaryToJson(this);
}
