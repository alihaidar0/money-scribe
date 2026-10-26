// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_kind_enum.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.isCustom,
    required this.key,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, Object?> json) =>
      _$CategoryFromJson(json);

  final String id;

  /// A custom category's own name; for a built-in one the English fallback of its `key`.
  final String name;

  /// A plain slug. Fall back to `other` for one the app does not know.
  final String icon;
  final CategoryKindEnum kind;
  @JsonKey(name: 'is_custom')
  final bool isCustom;

  /// The stable key of a built-in category (show its name from the app's own strings); `null` for a custom one.
  final String? key;
  final int version;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$CategoryToJson(this);
}
