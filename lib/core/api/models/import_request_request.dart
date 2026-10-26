// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dataset_enum.dart';
import 'rows.dart';

part 'import_request_request.g.dart';

@JsonSerializable()
class ImportRequestRequest {
  const ImportRequestRequest({
    required this.dataset,
    required this.rows,
    this.dryRun = false,
  });

  factory ImportRequestRequest.fromJson(Map<String, Object?> json) =>
      _$ImportRequestRequestFromJson(json);

  final DatasetEnum dataset;

  /// `true` answers what the call would do and writes nothing, stores nothing and needs no `Idempotency-Key`.
  @JsonKey(name: 'dry_run')
  final bool dryRun;

  /// Each row has `row` and the fields of the dataset, named like the CSV columns, with the JSON cells as arrays and an empty cell left out. A field that is not a column is a problem `read_only` on it.
  final List<Rows> rows;

  Map<String, Object?> toJson() => _$ImportRequestRequestToJson(this);
}
