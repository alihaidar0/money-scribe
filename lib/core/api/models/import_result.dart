// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dataset_enum.dart';
import 'import_problem.dart';

part 'import_result.g.dart';

@JsonSerializable()
class ImportResult {
  const ImportResult({
    required this.dataset,
    required this.dryRun,
    required this.imported,
    required this.skipped,
    required this.problems,
  });

  factory ImportResult.fromJson(Map<String, Object?> json) =>
      _$ImportResultFromJson(json);

  final DatasetEnum dataset;
  @JsonKey(name: 'dry_run')
  final bool dryRun;

  /// The rows written, or that a dry run would write.
  final int imported;

  /// The rows with a problem.
  final int skipped;

  /// One item per skipped row, the first problem of the row, ordered by `row`.
  final List<ImportProblem> problems;

  Map<String, Object?> toJson() => _$ImportResultToJson(this);
}
