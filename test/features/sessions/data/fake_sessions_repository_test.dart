import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

import '../../../support/fake_clock.dart';

void main() {
  late DemoController demo;
  late FakeSessionsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeSessionsRepository(
      demo: demo,
      clock: FixedClock(DateTime(2026, 10, 26, 10)),
    );
  });

  group('active', () {
    test('has this device first and the others after it', () async {
      final sessions = await repository.active();

      expect(sessions.map((s) => s.deviceName), [
        'Pixel 8',
        'Chrome on Windows',
      ]);
      expect(sessions.first.isCurrent, isTrue);
      expect(sessions.last.isCurrent, isFalse);
    });

    test('has only this device for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect((await repository.active()).single.isCurrent, isTrue);
    });

    test('reports no connection and a server failure', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await expectLater(
        repository.active(),
        throwsA(isA<NoConnectionException>()),
      );

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await expectLater(repository.active(), throwsA(isA<ServerException>()));
    });
  });

  group('ended', () {
    test('lists the ended sessions, newest sign-in first', () async {
      final page = await repository.ended();

      expect(page.items.map((s) => s.id), [
        'session-chrome-2',
        'session-pixel-2',
        'session-chrome-1',
      ]);
      expect(page.items.every((s) => s.isEnded), isTrue);
      expect(page.nextCursor, isNull);
    });

    test('comes in pages', () async {
      final small = FakeSessionsRepository(demo: demo, pageSize: 2);

      final first = await small.ended();
      final second = await small.ended(cursor: first.nextCursor);

      expect(first.items, hasLength(2));
      expect(first.nextCursor, isNotNull);
      expect(second.items, hasLength(1));
      expect(second.nextCursor, isNull);
    });

    test('has none for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect((await repository.ended()).items, isEmpty);
    });
  });

  group('end', () {
    test(
      'moves the session to the ended ones, as ended by the person',
      () async {
        await repository.end('session-chrome');

        expect((await repository.active()).map((s) => s.id), ['session-pixel']);
        final ended = (await repository.ended()).items.first;
        expect(ended.id, 'session-chrome');
        expect(ended.endReason, SessionEndReason.revokedByUser);
        expect(ended.endedAt, DateTime(2026, 10, 26, 10));
      },
    );

    test('never ends the session of this device', () async {
      await repository.end('session-pixel');

      expect(await repository.active(), hasLength(2));
    });

    test('ending one that is already ended does nothing', () async {
      await repository.end('missing');

      expect(await repository.active(), hasLength(2));
    });

    test('fails when the next save is set to fail', () async {
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.end('session-chrome'),
        throwsA(isA<NoConnectionException>()),
      );
      expect(await repository.active(), hasLength(2));
    });
  });

  group('endOthers', () {
    test('ends every session but this one and says how many', () async {
      final result = await repository.endOthers(password: 'secret');

      expect(result.sessionsEnded, 1);
      expect(result.keysRemoved, 1);
      expect((await repository.active()).single.isCurrent, isTrue);
      expect((await repository.ended()).items.first.id, 'session-chrome');
    });

    test('a wrong password is refused and ends nothing', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      await expectLater(
        repository.endOthers(password: 'nope'),
        throwsA(
          isA<SessionRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            SessionRefusal.wrongPassword,
          ),
        ),
      );
      expect(await repository.active(), hasLength(2));
    });
  });

  group('activity', () {
    test('lists the activity, newest first', () async {
      final page = await repository.activity();

      expect(page.items.first.id, 'event-export');
      expect(page.items.last.id, 'event-sign-in-chrome');
      expect(page.nextCursor, isNull);
    });

    test('comes in pages', () async {
      final small = FakeSessionsRepository(demo: demo, pageSize: 3);

      final first = await small.activity();
      final second = await small.activity(cursor: first.nextCursor);

      expect(first.items, hasLength(3));
      expect(second.items, hasLength(2));
      expect(second.nextCursor, isNull);
    });

    test('has none for an account with no data', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.empty));

      expect((await repository.activity()).items, isEmpty);
    });
  });

  test('tells the screens when the demo panel changes the data', () async {
    final changed = expectLater(repository.changes, emits(null));

    demo.update(const DemoSettings(scenario: DemoScenario.empty));

    await changed;
  });
}
