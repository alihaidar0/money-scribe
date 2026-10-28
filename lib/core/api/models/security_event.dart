// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'platform_enum.dart';
import 'security_event_type_enum.dart';
import 'sign_in_method_enum.dart';

part 'security_event.g.dart';

@JsonSerializable()
class SecurityEvent {
  const SecurityEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    required this.signInMethod,
    required this.sessionId,
    required this.kinds,
    required this.count,
  });

  factory SecurityEvent.fromJson(Map<String, Object?> json) =>
      _$SecurityEventFromJson(json);

  final String id;

  /// A client treats a type it does not know as an open value.
  ///
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
  final SecurityEventTypeEnum type;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  @JsonKey(name: 'device_name')
  final String? deviceName;
  final PlatformEnum? platform;
  @JsonKey(name: 'app_version')
  final String? appVersion;

  /// On `signed_in` only.
  ///
  /// * `password` - Password.
  /// * `email_code` - Email code.
  /// * `device_key` - Device key.
  @JsonKey(name: 'sign_in_method')
  final SignInMethodEnum? signInMethod;

  /// The session the entry belongs to, or `null`: the session may be gone.
  @JsonKey(name: 'session_id')
  final String? sessionId;

  /// On `data_exported` and `data_imported` only: which data (an open list).
  final List<String>? kinds;

  /// On `data_exported` and `data_imported` only: the rows written to the file or by the call, in total over the kinds; skipped rows are not counted.
  final int? count;

  Map<String, Object?> toJson() => _$SecurityEventToJson(this);
}
