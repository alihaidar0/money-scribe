import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';

DeviceSession session(
  String id, {
  String deviceId = 'd1',
  String name = 'Pixel 8',
  DateTime? endedAt,
  SessionEndReason? reason,
}) {
  return DeviceSession(
    id: id,
    deviceId: deviceId,
    deviceName: name,
    platform: SessionPlatform.android,
    osVersion: 'Android 15',
    appVersion: '1.0.0',
    signedInAt: DateTime(2026, 10),
    lastActiveAt: DateTime(2026, 10, 2),
    expiresAt: DateTime(2027),
    endedAt: endedAt,
    endReason: reason,
  );
}

SecurityEvent event(
  String id,
  SecurityEventType type,
  DateTime at, {
  String? sessionId,
  List<String> kinds = const [],
  int? count,
  String device = 'Pixel 8',
}) {
  return SecurityEvent(
    id: id,
    type: type,
    occurredAt: at,
    deviceName: device,
    sessionId: sessionId,
    kinds: kinds,
    count: count,
  );
}

void main() {
  group('DeviceSession', () {
    test('is ended when it has an end time or a reason', () {
      expect(session('a').isEnded, isFalse);
      expect(session('a', endedAt: DateTime(2026, 10, 5)).isEnded, isTrue);
      expect(session('a', reason: SessionEndReason.unknown).isEnded, isTrue);
    });

    test('endedBy keeps everything but how and when it ended', () {
      final ended = session('a')
          .endedBy(SessionEndReason.revokedByUser, DateTime(2026, 10, 9));

      expect(ended.isEnded, isTrue);
      expect(ended.endReason, SessionEndReason.revokedByUser);
      expect(ended.endedAt, DateTime(2026, 10, 9));
      expect(ended.deviceName, 'Pixel 8');
      expect(ended.isCurrent, isFalse);
    });
  });

  group('DeviceSessionGroup.group', () {
    test(
      'puts the sessions of one device together, in order of appearance',
      () {
        final groups = DeviceSessionGroup.group([
          session('a', deviceId: 'chrome', name: 'Chrome'),
          session('b', deviceId: 'pixel'),
          session('c', deviceId: 'chrome', name: 'Chrome'),
        ]);

        expect(groups.map((g) => g.deviceId), ['chrome', 'pixel']);
        expect(groups.first.sessions.map((s) => s.id), ['a', 'c']);
        expect(groups.last.sessions.map((s) => s.id), ['b']);
      },
    );

    test('the group is named by its newest session', () {
      final groups = DeviceSessionGroup.group([
        session('new', deviceId: 'd', name: 'Pixel 9'),
        session('old', deviceId: 'd'),
      ]);

      expect(groups.single.deviceName, 'Pixel 9');
    });

    test('has no group for no sessions', () {
      expect(DeviceSessionGroup.group(const []), isEmpty);
    });
  });

  group('groupImports', () {
    final noon = DateTime(2026, 10, 20, 12);

    test('puts imports of one session close together into one entry', () {
      final grouped = groupImports([
        event(
          '3',
          SecurityEventType.dataImported,
          noon.add(const Duration(minutes: 10)),
          sessionId: 's',
          kinds: ['debts'],
          count: 5,
        ),
        event(
          '2',
          SecurityEventType.dataImported,
          noon.add(const Duration(minutes: 5)),
          sessionId: 's',
          kinds: ['transactions'],
          count: 120,
        ),
        event(
          '1',
          SecurityEventType.dataImported,
          noon,
          sessionId: 's',
          kinds: ['transactions'],
          count: 80,
        ),
      ]);

      expect(grouped, hasLength(1));
      expect(grouped.single.count, 205);
      expect(grouped.single.kinds, ['debts', 'transactions']);
      // It is dated by the newest and keeps its id.
      expect(grouped.single.occurredAt, noon.add(const Duration(minutes: 10)));
      expect(grouped.single.id, '3');
    });

    test('a run goes on while each call follows the one before', () {
      final grouped = groupImports([
        event(
          '3',
          SecurityEventType.dataImported,
          noon.add(const Duration(minutes: 28)),
          sessionId: 's',
          count: 1,
        ),
        event(
          '2',
          SecurityEventType.dataImported,
          noon.add(const Duration(minutes: 14)),
          sessionId: 's',
          count: 1,
        ),
        event(
          '1',
          SecurityEventType.dataImported,
          noon,
          sessionId: 's',
          count: 1,
        ),
      ]);

      expect(grouped, hasLength(1));
      expect(grouped.single.count, 3);
    });

    test('imports 15 minutes or more apart stay apart', () {
      final grouped = groupImports([
        event(
          '2',
          SecurityEventType.dataImported,
          noon.add(const Duration(minutes: 15)),
          sessionId: 's',
        ),
        event('1', SecurityEventType.dataImported, noon, sessionId: 's'),
      ]);

      expect(grouped, hasLength(2));
    });

    test('imports of different sessions stay apart', () {
      final grouped = groupImports([
        event(
          '2',
          SecurityEventType.dataImported,
          noon.add(const Duration(minutes: 1)),
          sessionId: 'a',
        ),
        event('1', SecurityEventType.dataImported, noon, sessionId: 'b'),
      ]);

      expect(grouped, hasLength(2));
    });

    test('only imports next to each other are put together', () {
      final grouped = groupImports([
        event(
          '3',
          SecurityEventType.dataImported,
          noon.add(const Duration(minutes: 2)),
          sessionId: 's',
        ),
        event(
          '2',
          SecurityEventType.dataExported,
          noon.add(const Duration(minutes: 1)),
          sessionId: 's',
        ),
        event('1', SecurityEventType.dataImported, noon, sessionId: 's'),
      ]);

      expect(grouped.map((e) => e.id), ['3', '2', '1']);
    });

    test('exports are never put together', () {
      final grouped = groupImports([
        event(
          '2',
          SecurityEventType.dataExported,
          noon.add(const Duration(minutes: 1)),
        ),
        event('1', SecurityEventType.dataExported, noon),
      ]);

      expect(grouped, hasLength(2));
    });

    test('leaves a list with nothing to put together as it is', () {
      expect(groupImports(const []), isEmpty);
      final one = [event('1', SecurityEventType.signedIn, noon)];
      expect(groupImports(one), one);
    });
  });
}
