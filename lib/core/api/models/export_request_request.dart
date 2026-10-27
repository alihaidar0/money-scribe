// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'dataset_enum.dart';

part 'export_request_request.g.dart';

/// What to export and the password that allows it. ``from`` is a Python keyword, so it is added in ``get_fields``.
@JsonSerializable()
class ExportRequestRequest {
  const ExportRequestRequest({
    required this.kinds,
    required this.currentPassword,
    this.from,
    this.to,
  });

  factory ExportRequestRequest.fromJson(Map<String, Object?> json) =>
      _$ExportRequestRequestFromJson(json);

  /// 1 to 5 different kinds. One kind is answered as a CSV file, several as a ZIP archive with one file per kind (always in the order accounts, categories, transactions, debts, salary months).
  final List<DatasetEnum> kinds;

  /// The account password; it is never put in a URL.
  @JsonKey(name: 'current_password')
  final String currentPassword;

  /// The first day, inclusive (`YYYY-MM-DD`). It applies to a transaction's `date`, a debt's `start_date` and, counted in months, to a salary month's month; accounts and categories have no date, so it does not apply to them. Both left out means all time.
  final DateTime? from;

  /// The last day, inclusive (`YYYY-MM-DD`); the same rules as `from`.
  final DateTime? to;

  Map<String, Object?> toJson() => _$ExportRequestRequestToJson(this);
}
