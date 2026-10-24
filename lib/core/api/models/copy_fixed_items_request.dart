// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'copy_fixed_items_request.g.dart';

/// The body of the copy: ``{"from": "YYYY-MM"}``, which may be left out. ``from`` is a Python keyword.
@JsonSerializable()
class CopyFixedItemsRequest {
  const CopyFixedItemsRequest({this.from});

  factory CopyFixedItemsRequest.fromJson(Map<String, Object?> json) =>
      _$CopyFixedItemsRequestFromJson(json);

  /// The month to copy the items from, `YYYY-MM`. Default: the most recent saved month before this one.
  final String? from;

  Map<String, Object?> toJson() => _$CopyFixedItemsRequestToJson(this);
}
