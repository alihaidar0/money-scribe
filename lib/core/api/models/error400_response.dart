// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'error400_response_type_enum.dart';
import 'error_item.dart';

part 'error400_response.g.dart';

/// ``validation_error``: invalid input. ``client_error``: an unreadable request body.
@JsonSerializable()
class Error400Response {
  const Error400Response({required this.type, required this.errors});

  factory Error400Response.fromJson(Map<String, Object?> json) =>
      _$Error400ResponseFromJson(json);

  final Error400ResponseTypeEnum type;
  final List<ErrorItem> errors;

  Map<String, Object?> toJson() => _$Error400ResponseToJson(this);
}
