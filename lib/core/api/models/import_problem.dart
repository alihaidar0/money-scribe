// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'import_problem.g.dart';

@JsonSerializable()
class ImportProblem {
  const ImportProblem({
    required this.row,
    required this.code,
    required this.attr,
  });

  factory ImportProblem.fromJson(Map<String, Object?> json) =>
      _$ImportProblemFromJson(json);

  final int row;

  /// The code of a single create's rule, or `unknown_category`, `unknown_account`, `duplicate`, `read_only` or a limit code. A plain string: a client survives a code it does not know.
  final String code;

  /// The field of the row that is wrong (dotted inside `repayments` and `fixed_items`), or `null`.
  final String? attr;

  Map<String, Object?> toJson() => _$ImportProblemToJson(this);
}
