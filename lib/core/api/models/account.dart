// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'account_kind_enum.dart';

part 'account.g.dart';

@JsonSerializable()
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromJson(Map<String, Object?> json) =>
      _$AccountFromJson(json);

  final String id;
  final String name;
  final AccountKindEnum kind;
  final int version;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$AccountToJson(this);
}
