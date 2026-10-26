import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';

/// Invented devices and activity for the fake server, from the sample of
/// `docs/stitch-prompts.md`. Never real devices, networks or addresses: the
/// networks are the ones reserved for documentation.
abstract final class SessionsSeed {
  static final _pixel = DeviceSession(
    id: 'session-pixel',
    deviceId: 'device-pixel',
    deviceName: 'Pixel 8',
    platform: SessionPlatform.android,
    osVersion: 'Android 15',
    appVersion: '1.4.0+52',
    signedInAt: DateTime(2026, 10, 20, 8),
    lastActiveAt: DateTime(2026, 10, 25, 18, 40),
    expiresAt: DateTime(2027, 1, 18),
    isCurrent: true,
    signInMethod: SignInMethod.deviceKey,
    network: '203.0.113.0/24',
  );

  static final _chrome = DeviceSession(
    id: 'session-chrome',
    deviceId: 'device-chrome',
    deviceName: 'Chrome on Windows',
    platform: SessionPlatform.web,
    osVersion: 'Windows 11',
    appVersion: '1.4.0',
    signedInAt: DateTime(2026, 10, 22, 9, 30),
    lastActiveAt: DateTime(2026, 10, 24, 20, 15),
    expiresAt: DateTime(2027, 1, 20),
    signInMethod: SignInMethod.password,
    network: '198.51.100.0/24',
  );

  /// The sessions that are active, the current one first.
  static List<DeviceSession> active() => [_pixel, _chrome];

  /// The sessions of an account that has only the current one.
  static List<DeviceSession> onlyCurrent() => [_pixel];

  /// The sessions that ended, newest sign-in first.
  static List<DeviceSession> ended() {
    return [
      DeviceSession(
        id: 'session-chrome-2',
        deviceId: 'device-chrome',
        deviceName: 'Chrome on Windows',
        platform: SessionPlatform.web,
        osVersion: 'Windows 10',
        appVersion: '1.3.2',
        signedInAt: DateTime(2026, 10, 12, 9, 30),
        lastActiveAt: DateTime(2026, 10, 14, 20, 15),
        expiresAt: DateTime(2027, 1, 10),
        signInMethod: SignInMethod.password,
        network: '198.51.100.0/24',
        endedAt: DateTime(2026, 10, 14, 20, 20),
        endReason: SessionEndReason.passwordChanged,
      ),
      DeviceSession(
        id: 'session-pixel-2',
        deviceId: 'device-pixel',
        deviceName: 'Pixel 8',
        platform: SessionPlatform.android,
        osVersion: 'Android 15',
        appVersion: '1.3.2+48',
        signedInAt: DateTime(2026, 10, 5, 8, 10),
        lastActiveAt: DateTime(2026, 10, 20, 7, 55),
        expiresAt: DateTime(2027, 1, 3),
        signInMethod: SignInMethod.deviceKey,
        network: '203.0.113.0/24',
        endedAt: DateTime(2026, 10, 20, 8),
        endReason: SessionEndReason.signedOut,
      ),
      DeviceSession(
        id: 'session-chrome-1',
        deviceId: 'device-chrome',
        deviceName: 'Chrome on Windows',
        platform: SessionPlatform.web,
        osVersion: 'Windows 10',
        appVersion: '1.3.0',
        signedInAt: DateTime(2026, 9, 2, 10),
        lastActiveAt: DateTime(2026, 9, 3, 12),
        expiresAt: DateTime(2026, 12),
        signInMethod: SignInMethod.emailCode,
        endedAt: DateTime(2026, 10, 2, 10),
        endReason: SessionEndReason.expired,
      ),
    ];
  }

  /// The security activity, newest first.
  static List<SecurityEvent> activity() {
    return [
      SecurityEvent(
        id: 'event-export',
        type: SecurityEventType.dataExported,
        occurredAt: DateTime(2026, 10, 25, 18, 45),
        deviceName: 'Pixel 8',
        platform: SessionPlatform.android,
        sessionId: 'session-pixel',
        kinds: const ['transactions'],
        count: 125,
      ),
      SecurityEvent(
        id: 'event-sign-in-pixel',
        type: SecurityEventType.signedIn,
        occurredAt: DateTime(2026, 10, 20, 8),
        deviceName: 'Pixel 8',
        platform: SessionPlatform.android,
        signInMethod: SignInMethod.deviceKey,
        sessionId: 'session-pixel',
      ),
      SecurityEvent(
        id: 'event-password',
        type: SecurityEventType.passwordChanged,
        occurredAt: DateTime(2026, 10, 14, 20, 20),
        deviceName: 'Chrome on Windows',
        platform: SessionPlatform.web,
      ),
      SecurityEvent(
        id: 'event-reuse',
        type: SecurityEventType.tokenReuseDetected,
        occurredAt: DateTime(2026, 10, 13, 11, 5),
        deviceName: 'Chrome on Windows',
        platform: SessionPlatform.web,
      ),
      SecurityEvent(
        id: 'event-sign-in-chrome',
        type: SecurityEventType.signedIn,
        occurredAt: DateTime(2026, 10, 12, 9, 30),
        deviceName: 'Chrome on Windows',
        platform: SessionPlatform.web,
        signInMethod: SignInMethod.password,
        sessionId: 'session-chrome-2',
      ),
    ];
  }
}
