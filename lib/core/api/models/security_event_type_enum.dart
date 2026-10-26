// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `signed_in` - Signed in.
/// * `signed_out` - Signed out.
/// * `session_revoked` - Session revoked.
/// * `session_limit_reached` - Session limit reached.
/// * `password_changed` - Password changed.
/// * `password_reset` - Password reset.
/// * `email_changed` - Email changed.
/// * `device_key_added` - Device key added.
/// * `device_key_removed` - Device key removed.
/// * `token_reuse_detected` - Token reuse detected.
/// * `data_exported` - Data exported.
/// * `data_imported` - Data imported.
@JsonEnum()
enum SecurityEventTypeEnum {
  @JsonValue('signed_in')
  signedIn('signed_in'),
  @JsonValue('signed_out')
  signedOut('signed_out'),
  @JsonValue('session_revoked')
  sessionRevoked('session_revoked'),
  @JsonValue('session_limit_reached')
  sessionLimitReached('session_limit_reached'),
  @JsonValue('password_changed')
  passwordChanged('password_changed'),
  @JsonValue('password_reset')
  passwordReset('password_reset'),
  @JsonValue('email_changed')
  emailChanged('email_changed'),
  @JsonValue('device_key_added')
  deviceKeyAdded('device_key_added'),
  @JsonValue('device_key_removed')
  deviceKeyRemoved('device_key_removed'),
  @JsonValue('token_reuse_detected')
  tokenReuseDetected('token_reuse_detected'),
  @JsonValue('data_exported')
  dataExported('data_exported'),
  @JsonValue('data_imported')
  dataImported('data_imported'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const SecurityEventTypeEnum(this.json);

  factory SecurityEventTypeEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<SecurityEventTypeEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
