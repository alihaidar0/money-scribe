/// A session as the server sends it: an active one of a Pixel, unless it is
/// given an [endReason].
Map<String, Object?> sessionJson({
  String id = '0198f2d0-0000-7000-8000-000000000001',
  String deviceId = 'device-1',
  String deviceName = 'Pixel 8',
  String platform = 'android',
  String osVersion = 'Android 15',
  String appVersion = '1.4.0+52',
  String signedInAt = '2026-10-20T08:00:00Z',
  String lastActiveAt = '2026-10-25T18:40:00Z',
  String expiresAt = '2027-01-18T08:00:00Z',
  bool isCurrent = false,
  String signInMethod = 'password',
  String? network = '203.0.113.0/24',
  String? endedAt,
  String? endReason,
}) {
  return {
    'id': id,
    'device_id': deviceId,
    'device_name': deviceName,
    'platform': platform,
    'os_version': osVersion,
    'app_version': appVersion,
    'signed_in_at': signedInAt,
    'last_active_at': lastActiveAt,
    'expires_at': expiresAt,
    'is_current': isCurrent,
    'sign_in_method': signInMethod,
    'network': network,
    'ended_at': endedAt,
    'end_reason': endReason,
  };
}

/// An entry of the security activity as the server sends it.
Map<String, Object?> eventJson({
  String id = '0198f2e0-0000-7000-8000-000000000001',
  String type = 'signed_in',
  String occurredAt = '2026-10-20T08:00:00Z',
  String? deviceName = 'Pixel 8',
  String? platform = 'android',
  String? appVersion = '1.4.0+52',
  String? signInMethod,
  String? sessionId,
  List<String>? kinds,
  int? count,
}) {
  return {
    'id': id,
    'type': type,
    'occurred_at': occurredAt,
    'device_name': deviceName,
    'platform': platform,
    'app_version': appVersion,
    'sign_in_method': signInMethod,
    'session_id': sessionId,
    'kinds': kinds,
    'count': count,
  };
}
