// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'platform_enum.dart';
import 'sign_in_method_enum.dart';

part 'session.g.dart';

/// A session of the person. The serializer is given a ``Session`` and ``current_id`` in its context.
@JsonSerializable()
class Session {
  const Session({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.signedInAt,
    required this.lastActiveAt,
    required this.expiresAt,
    required this.isCurrent,
    required this.signInMethod,
    required this.network,
    required this.endedAt,
    required this.endReason,
  });

  factory Session.fromJson(Map<String, Object?> json) =>
      _$SessionFromJson(json);

  /// The session id, also the `sid` of its tokens. An identifier, not a credential.
  final String id;

  /// The install id of the device; several sessions of one device share it, so the app can group them.
  @JsonKey(name: 'device_id')
  final String deviceId;

  /// As the device sent it; shown, never parsed.
  @JsonKey(name: 'device_name')
  final String deviceName;
  final PlatformEnum platform;

  /// As the device sent it; shown, never parsed.
  @JsonKey(name: 'os_version')
  final String osVersion;

  /// As the device sent it (`1.0.0+1`); shown, never parsed.
  @JsonKey(name: 'app_version')
  final String appVersion;
  @JsonKey(name: 'signed_in_at')
  final DateTime signedInAt;

  /// Updated at most once every 5 minutes.
  @JsonKey(name: 'last_active_at')
  final DateTime lastActiveAt;

  /// The 90 day limit of the session.
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  /// The session of this very request. Always `false` for an ended session.
  @JsonKey(name: 'is_current')
  final bool isCurrent;
  @JsonKey(name: 'sign_in_method')
  final SignInMethodEnum signInMethod;

  /// The address the session was last seen at, cut to its network (`203.0.113.0/24`, a `/48` for IPv6), or `null`. A full address and a user agent are never returned.
  final String? network;

  /// `null` for an active session. For a session whose refresh token ran out it is the moment it ran out.
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;

  /// `null` for an active session, else why it ended: `signed_out`, `revoked_by_user`, `expired`, `session_limit`, `password_changed`, `password_reset`, `email_changed`, `token_reuse` or `replaced`. A client treats a value it does not know as a generic "ended".
  @JsonKey(name: 'end_reason')
  final String? endReason;

  Map<String, Object?> toJson() => _$SessionToJson(this);
}
