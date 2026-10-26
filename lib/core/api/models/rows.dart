// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'rows.g.dart';

@JsonSerializable()
class Rows {
  const Rows({required this.row});

  factory Rows.fromJson(Map<String, Object?> json) => _$RowsFromJson(json);

  /// The line in the file; unique in the call.
  final int row;

  Map<String, Object?> toJson() => _$RowsToJson(this);
}
