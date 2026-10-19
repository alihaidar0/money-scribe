// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'client_error_enum.dart';
import 'error_item.dart';

part 'error_response.g.dart';

/// ``client_error``: a 401, 403, 404, 409 or 429 answer; ``Retry-After`` accompanies a 429.
@JsonSerializable()
class ErrorResponse {
  const ErrorResponse({required this.type, required this.errors});

  factory ErrorResponse.fromJson(Map<String, Object?> json) =>
      _$ErrorResponseFromJson(json);

  final ClientErrorEnum type;
  final List<ErrorItem> errors;

  Map<String, Object?> toJson() => _$ErrorResponseToJson(this);
}
