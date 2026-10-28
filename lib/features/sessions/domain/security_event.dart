import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';

/// What happened. A type this version of the app does not know is [unknown]
/// and is shown with generic wording.
enum SecurityEventType {
  signedIn,
  signedOut,
  sessionRevoked,
  sessionLimitReached,
  passwordChanged,
  passwordReset,
  emailChanged,
  deviceKeyAdded,
  deviceKeyRemoved,
  tokenReuseDetected,
  dataExported,
  dataImported,
  unknown,
}

/// One line of the security activity of the account.
///
/// For [SecurityEventType.sessionRevoked],
/// [SecurityEventType.sessionLimitReached] and
/// [SecurityEventType.tokenReuseDetected] the device is the one that was
/// ended. Failed sign-ins and the deletion of the account are not entries.
final class SecurityEvent extends Equatable {
  const new({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.deviceName,
    this.platform,
    this.appVersion,
    this.signInMethod,
    this.sessionId,
    this.kinds = const [],
    this.count,
  });

  final String id;
  final SecurityEventType type;
  final DateTime occurredAt;
  final String? deviceName;
  final SessionPlatform? platform;
  final String? appVersion;

  /// On a sign-in only.
  final SignInMethod? signInMethod;

  /// The session the entry belongs to, or `null`: the session may be gone.
  final String? sessionId;

  /// On an export or an import: which data, such as `transactions`. An open
  /// list: a kind the app does not know is shown as it is.
  final List<String> kinds;

  /// On an export or an import: the rows written, in total over the kinds.
  final int? count;

  @override
  List<Object?> get props => [
    id,
    type,
    occurredAt,
    deviceName,
    platform,
    appVersion,
    signInMethod,
    sessionId,
    kinds,
    count,
  ];
}

/// A page of the activity, newest first, and where the next page is (`null` on
/// the last one).
final class SecurityEventsPage extends Equatable {
  const new({required this.items, this.nextCursor});

  final List<SecurityEvent> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}

/// Puts the imports of one import action together. One import of many rows is
/// written as one entry for each call, so a run of imports of one session in
/// which each call follows the one before within 15 minutes is shown as one:
/// the rows are added up and the kinds joined, and it is dated by the newest.
///
/// [events] are newest first, as the server sends them, and only entries next
/// to each other are put together.
List<SecurityEvent> groupImports(List<SecurityEvent> events) {
  const gap = Duration(minutes: 15);
  final result = <SecurityEvent>[];
  // The time of the oldest call put into the last entry of [result].
  var oldestCall = DateTime.fromMillisecondsSinceEpoch(0);
  for (final event in events) {
    final previous = result.lastOrNull;
    final together =
        previous != null &&
        previous.type == SecurityEventType.dataImported &&
        event.type == SecurityEventType.dataImported &&
        previous.sessionId == event.sessionId &&
        previous.deviceName == event.deviceName &&
        oldestCall.difference(event.occurredAt).abs() < gap;
    if (together) {
      result[result.length - 1] = SecurityEvent(
        id: previous.id,
        type: previous.type,
        occurredAt: previous.occurredAt,
        deviceName: previous.deviceName,
        platform: previous.platform,
        appVersion: previous.appVersion,
        sessionId: previous.sessionId,
        kinds: [
          ...previous.kinds,
          for (final kind in event.kinds)
            if (!previous.kinds.contains(kind)) kind,
        ],
        count: (previous.count ?? 0) + (event.count ?? 0),
      );
    } else {
      result.add(event);
    }
    oldestCall = event.occurredAt;
  }
  return result;
}
