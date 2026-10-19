// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error_item.dart';
import 'server_error_enum.dart';

part 'server_error_response.g.dart';

/// ``server_error``: a 503 answer, always with ``Retry-After``; its one code is ``service_unavailable``.
@JsonSerializable()
class ServerErrorResponse {
  const ServerErrorResponse({required this.type, required this.errors});

  factory ServerErrorResponse.fromJson(Map<String, Object?> json) =>
      _$ServerErrorResponseFromJson(json);

  final ServerErrorEnum type;
  final List<ErrorItem> errors;

  Map<String, Object?> toJson() => _$ServerErrorResponseToJson(this);
}
