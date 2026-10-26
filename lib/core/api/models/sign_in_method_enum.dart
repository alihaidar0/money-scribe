// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `password` - Password.
/// * `email_code` - Email code.
/// * `device_key` - Device key.
@JsonEnum()
enum SignInMethodEnum {
  @JsonValue('password')
  password('password'),
  @JsonValue('email_code')
  emailCode('email_code'),
  @JsonValue('device_key')
  deviceKey('device_key'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const SignInMethodEnum(this.json);

  factory SignInMethodEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<SignInMethodEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
