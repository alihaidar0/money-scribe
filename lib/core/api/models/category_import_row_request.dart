// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'icon_enum.dart';

part 'category_import_row_request.g.dart';

/// A custom category of the file. One whose name exists, in any case, is a `duplicate` and keeps its icon.
@JsonSerializable()
class CategoryImportRowRequest {
  const CategoryImportRowRequest({
    required this.row,
    required this.name,
    required this.icon,
  });

  factory CategoryImportRowRequest.fromJson(Map<String, Object?> json) =>
      _$CategoryImportRowRequestFromJson(json);

  /// The line in the file: a positive whole number, unique in the call.
  final int row;

  /// 1 to 30 characters, trimmed.
  final String name;

  /// One of the icons the picker offers for a custom category. There is no default for a missing one.
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

  Map<String, Object?> toJson() => _$CategoryImportRowRequestToJson(this);
}
