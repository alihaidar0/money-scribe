// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'account_kind_enum.dart';

part 'account_import_row_request.g.dart';

/// An account of the file. One whose name exists, in any case, is a `duplicate`.
@JsonSerializable()
class AccountImportRowRequest {
  const AccountImportRowRequest({
    required this.row,
    required this.name,
    required this.kind,
  });

  factory AccountImportRowRequest.fromJson(Map<String, Object?> json) =>
      _$AccountImportRowRequestFromJson(json);

  /// The line in the file: a positive whole number, unique in the call.
  final int row;

  /// 1 to 30 characters, trimmed.
  final String name;
  final AccountKindEnum kind;

  Map<String, Object?> toJson() => _$AccountImportRowRequestToJson(this);
}
