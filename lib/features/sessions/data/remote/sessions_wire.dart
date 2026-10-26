import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';

/// Turns what the server sends about sessions and the security activity into
/// the types of the app. A value the app does not know yet (a platform, a way
/// of signing in, a reason a session ended, a kind of entry) is read as
/// "unknown" and shown with generic wording, so a newer server never breaks an
/// older app.
abstract final class SessionsWire {
  static SessionPlatform platform(api.PlatformEnum? wire) {
    return switch (wire) {
      api.PlatformEnum.android => SessionPlatform.android,
      api.PlatformEnum.ios => SessionPlatform.ios,
      api.PlatformEnum.web => SessionPlatform.web,
      api.PlatformEnum.$unknown || null => SessionPlatform.unknown,
    };
  }

  static SignInMethod method(api.SignInMethodEnum? wire) {
    return switch (wire) {
      api.SignInMethodEnum.password => SignInMethod.password,
      api.SignInMethodEnum.emailCode => SignInMethod.emailCode,
      api.SignInMethodEnum.deviceKey => SignInMethod.deviceKey,
      api.SignInMethodEnum.$unknown || null => SignInMethod.unknown,
    };
  }

  static SessionEndReason? endReason(String? wire) {
    if (wire == null) return null;
    return switch (wire) {
      'signed_out' => SessionEndReason.signedOut,
      'revoked_by_user' => SessionEndReason.revokedByUser,
      'expired' => SessionEndReason.expired,
      'session_limit' => SessionEndReason.sessionLimit,
      'password_changed' => SessionEndReason.passwordChanged,
      'password_reset' => SessionEndReason.passwordReset,
      'email_changed' => SessionEndReason.emailChanged,
      'token_reuse' => SessionEndReason.tokenReuse,
      'replaced' => SessionEndReason.replaced,
      _ => SessionEndReason.unknown,
    };
  }

  static DeviceSession session(api.Session wire) {
    return DeviceSession(
      id: wire.id,
      deviceId: wire.deviceId,
      deviceName: wire.deviceName,
      platform: platform(wire.platform),
      osVersion: wire.osVersion,
      appVersion: wire.appVersion,
      signedInAt: wire.signedInAt,
      lastActiveAt: wire.lastActiveAt,
      expiresAt: wire.expiresAt,
      isCurrent: wire.isCurrent,
      signInMethod: method(wire.signInMethod),
      network: wire.network,
      endedAt: wire.endedAt,
      endReason: endReason(wire.endReason),
    );
  }

  static SecurityEventType eventType(api.SecurityEventTypeEnum wire) {
    return switch (wire) {
      api.SecurityEventTypeEnum.signedIn => SecurityEventType.signedIn,
      api.SecurityEventTypeEnum.signedOut => SecurityEventType.signedOut,
      api.SecurityEventTypeEnum.sessionRevoked =>
        SecurityEventType.sessionRevoked,
      api.SecurityEventTypeEnum.sessionLimitReached =>
        SecurityEventType.sessionLimitReached,
      api.SecurityEventTypeEnum.passwordChanged =>
        SecurityEventType.passwordChanged,
      api.SecurityEventTypeEnum.passwordReset =>
        SecurityEventType.passwordReset,
      api.SecurityEventTypeEnum.emailChanged => SecurityEventType.emailChanged,
      api.SecurityEventTypeEnum.deviceKeyAdded =>
        SecurityEventType.deviceKeyAdded,
      api.SecurityEventTypeEnum.deviceKeyRemoved =>
        SecurityEventType.deviceKeyRemoved,
      api.SecurityEventTypeEnum.tokenReuseDetected =>
        SecurityEventType.tokenReuseDetected,
      api.SecurityEventTypeEnum.dataExported => SecurityEventType.dataExported,
      api.SecurityEventTypeEnum.dataImported => SecurityEventType.dataImported,
      api.SecurityEventTypeEnum.$unknown => SecurityEventType.unknown,
    };
  }

  static SecurityEvent event(api.SecurityEvent wire) {
    return SecurityEvent(
      id: wire.id,
      type: eventType(wire.type),
      occurredAt: wire.occurredAt,
      deviceName: wire.deviceName,
      platform: wire.platform == null ? null : platform(wire.platform),
      appVersion: wire.appVersion,
      signInMethod: wire.signInMethod == null
          ? null
          : method(wire.signInMethod),
      sessionId: wire.sessionId,
      kinds: wire.kinds ?? const [],
      count: wire.count,
    );
  }
}
