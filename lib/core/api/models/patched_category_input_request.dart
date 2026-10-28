// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'icon_enum.dart';

part 'patched_category_input_request.g.dart';

/// A custom category to add or to change. Its kind is always `both`; a `kind` here is `400 read_only`.
@JsonSerializable()
class PatchedCategoryInputRequest {
  const PatchedCategoryInputRequest({required this.name, required this.icon});

  factory PatchedCategoryInputRequest.fromJson(Map<String, Object?> json) =>
      _$PatchedCategoryInputRequestFromJson(json);

  /// 1 to 30 characters, trimmed. Unique among the person's custom categories, in any case, and not a built-in key or English name: `400 name_taken`.
  final String name;

  /// One of the icons the picker offers for a custom category.
  ///
  /// * `gifts` - gifts.
  /// * `health` - health.
  /// * `entertainment` - entertainment.
  /// * `shopping` - shopping.
  /// * `education` - education.
  /// * `travel` - travel.
  /// * `subscriptions` - subscriptions.
  /// * `other` - other.
  final IconEnum icon;

  Map<String, Object?> toJson() => _$PatchedCategoryInputRequestToJson(this);
}
