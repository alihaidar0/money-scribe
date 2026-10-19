// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `validation_error` - Validation Error.
/// * `client_error` - Client Error.
@JsonEnum()
enum Error400ResponseTypeEnum {
  @JsonValue('validation_error')
  validationError('validation_error'),
  @JsonValue('client_error')
  clientError('client_error'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Error400ResponseTypeEnum(this.json);

  factory Error400ResponseTypeEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<Error400ResponseTypeEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
