import 'package:equatable/equatable.dart';

/// The kind of device a session or an activity entry came from. A platform
/// this version of the app does not know is [unknown].
enum SessionPlatform { android, ios, web, unknown }

/// How the person signed in. A method this version of the app does not know is
/// [unknown] and is not named.
enum SignInMethod { password, emailCode, deviceKey, unknown }

/// Why a session ended. A reason this version of the app does not know is
/// [unknown] and reads as a plain "ended".
enum SessionEndReason {
  signedOut,
  revokedByUser,
  expired,
  sessionLimit,
  passwordChanged,
  passwordReset,
  emailChanged,
  tokenReuse,
  replaced,
  unknown,
}

/// A sign-in of this account on a device, active or ended.
///
/// The server sends the device name, the system and the app version as the
/// device wrote them: they are shown, never parsed. [network] is the address
/// cut to its network, never a full address.
final class DeviceSession extends Equatable {
  const new({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.signedInAt,
    required this.lastActiveAt,
    required this.expiresAt,
    this.isCurrent = false,
    this.signInMethod = SignInMethod.unknown,
    this.network,
    this.endedAt,
    this.endReason,
  });

  final String id;

  /// The install the session belongs to. Several sessions of one device share
  /// it, so the ended ones are grouped by it.
  final String deviceId;
  final String deviceName;
  final SessionPlatform platform;
  final String osVersion;
  final String appVersion;
  final DateTime signedInAt;
  final DateTime lastActiveAt;

  /// The day the session reaches its 90-day limit.
  final DateTime expiresAt;

  /// Whether this is the session of the device the app runs on.
  final bool isCurrent;
  final SignInMethod signInMethod;

  /// The network the session was last seen on, such as `203.0.113.0/24`.
  final String? network;

  /// When the session ended, for an ended one.
  final DateTime? endedAt;

  /// Why the session ended, for an ended one.
  final SessionEndReason? endReason;

  /// Whether the session has ended.
  bool get isEnded => endedAt != null || endReason != null;

  /// This session as an ended one: [reason] and [at] say how and when.
  DeviceSession endedBy(SessionEndReason reason, DateTime at) {
    return DeviceSession(
      id: id,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      signedInAt: signedInAt,
      lastActiveAt: lastActiveAt,
      expiresAt: expiresAt,
      signInMethod: signInMethod,
      network: network,
      endedAt: at,
      endReason: reason,
    );
  }

  @override
  List<Object?> get props => [
    id,
    deviceId,
    deviceName,
    platform,
    osVersion,
    appVersion,
    signedInAt,
    lastActiveAt,
    expiresAt,
    isCurrent,
    signInMethod,
    network,
    endedAt,
    endReason,
  ];
}

/// The ended sessions of one device, newest first.
final class DeviceSessionGroup extends Equatable {
  const new({
    required this.deviceId,
    required this.deviceName,
    required this.sessions,
  });

  final String deviceId;

  /// The name of the device as its newest session knows it.
  final String deviceName;
  final List<DeviceSession> sessions;

  /// The sessions grouped by device, in the order the devices first appear.
  /// A device that signed in five times is one group of five rows.
  static List<DeviceSessionGroup> group(List<DeviceSession> sessions) {
    final byDevice = <String, List<DeviceSession>>{};
    for (final session in sessions) {
      byDevice.putIfAbsent(session.deviceId, () => []).add(session);
    }
    return [
      for (final MapEntry(key: id, value: list) in byDevice.entries)
        DeviceSessionGroup(
          deviceId: id,
          deviceName: list.first.deviceName,
          sessions: List.unmodifiable(list),
        ),
    ];
  }

  @override
  List<Object> get props => [deviceId, deviceName, sessions];
}

/// A page of ended sessions: the sessions, and where the next page is (`null`
/// on the last one).
final class SessionsPage extends Equatable {
  const new({required this.items, this.nextCursor});

  final List<DeviceSession> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
