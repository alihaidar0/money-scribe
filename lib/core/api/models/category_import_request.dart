// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_import_dataset_enum.dart';
import 'category_import_row_request.dart';
import 'import_request.dart';

part 'category_import_request.g.dart';

@JsonSerializable()
class CategoryImportRequest {
  const CategoryImportRequest({
    required this.dataset,
    required this.rows,
    this.dryRun = false,
  });

  factory CategoryImportRequest.fromJson(Map<String, Object?> json) =>
      _$CategoryImportRequestFromJson(json);

  /// `true` answers what the call would do and writes nothing, stores nothing and needs no `Idempotency-Key`.
  @JsonKey(name: 'dry_run')
  final bool dryRun;

  /// The rows are `categories` rows.
  ///
  /// * `categories` - categories.
  final CategoryImportDatasetEnum dataset;

  /// 1 to 500 rows. A field that is not a column of the dataset is a problem `read_only` on it, and an empty cell is left out.
  final List<CategoryImportRowRequest> rows;

  Map<String, Object?> toJson() => _$CategoryImportRequestToJson(this);
}
