import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/sessions/data/remote/remote_sessions_repository.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

import '../../../support/fake_http_adapter.dart';
import '../../transactions/data/transactions_json.dart';
import 'sessions_json.dart';

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;

  RemoteSessionsRepository build() {
    return RemoteSessionsRepository.create(dio: transactionsTestDio(server));
  }

  RequestOptions lastRequest() => server.requests.last;

  setUp(() {
    answer = (_) => jsonBody(200, pageJson([sessionJson()]));
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('active', () {
    test('asks for the active sessions and reads them', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          sessionJson(isCurrent: true, signInMethod: 'device_key'),
          sessionJson(
            id: 'other',
            deviceName: 'Chrome on Windows',
            platform: 'web',
            network: null,
          ),
        ]),
      );

      final sessions = await build().active();

      expect(lastRequest().path, '/api/v1/auth/sessions/');
      expect(lastRequest().uri.queryParameters['status'], 'active');
      expect(sessions, hasLength(2));
      final current = sessions.first;
      expect(current.isCurrent, isTrue);
      expect(current.deviceName, 'Pixel 8');
      expect(current.platform, SessionPlatform.android);
      expect(current.osVersion, 'Android 15');
      expect(current.appVersion, '1.4.0+52');
      expect(current.signInMethod, SignInMethod.deviceKey);
      expect(current.network, '203.0.113.0/24');
      expect(current.isEnded, isFalse);
      expect(current.signedInAt, DateTime.utc(2026, 10, 20, 8));
      expect(sessions.last.platform, SessionPlatform.web);
      expect(sessions.last.network, isNull);
    });

    test(
      'a platform and a method the app does not know read as unknown',
      () async {
        answer = (_) => jsonBody(
          200,
          pageJson([sessionJson(platform: 'tv', signInMethod: 'passkey')]),
        );

        final session = (await build().active()).single;

        expect(session.platform, SessionPlatform.unknown);
        expect(session.signInMethod, SignInMethod.unknown);
      },
    );

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().active(), throwsA(isA<NoConnectionException>()));
    });

    test('a failure of the server is a server failure', () {
      answer = (_) => jsonBody(500, errorBody('server_error'));

      expect(build().active(), throwsA(isA<ServerException>()));
    });
  });

  group('ended', () {
    test('asks for the ended sessions a page at a time', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          sessionJson(
            endedAt: '2026-10-21T10:00:00Z',
            endReason: 'password_changed',
          ),
        ], next: 'https://api.example.test/api/v1/auth/sessions/?cursor=abc'),
      );

      final page = await build().ended(cursor: 'prev');

      final query = lastRequest().uri.queryParameters;
      expect(query['status'], 'ended');
      expect(query['cursor'], 'prev');
      expect(query['limit'], '50');
      expect(page.nextCursor, 'abc');
      expect(page.items.single.isEnded, isTrue);
      expect(page.items.single.endReason, SessionEndReason.passwordChanged);
      expect(page.items.single.endedAt, DateTime.utc(2026, 10, 21, 10));
    });

    test(
      'knows every reason, and reads one it does not know as unknown',
      () async {
        const reasons = {
          'signed_out': SessionEndReason.signedOut,
          'revoked_by_user': SessionEndReason.revokedByUser,
          'expired': SessionEndReason.expired,
          'session_limit': SessionEndReason.sessionLimit,
          'password_changed': SessionEndReason.passwordChanged,
          'password_reset': SessionEndReason.passwordReset,
          'email_changed': SessionEndReason.emailChanged,
          'token_reuse': SessionEndReason.tokenReuse,
          'replaced': SessionEndReason.replaced,
          'something_new': SessionEndReason.unknown,
        };
        answer = (_) => jsonBody(
          200,
          pageJson([
            for (final reason in reasons.keys)
              sessionJson(endedAt: '2026-10-21T10:00:00Z', endReason: reason),
          ]),
        );

        final page = await build().ended();

        expect(page.items.map((s) => s.endReason), reasons.values);
      },
    );

    test('the last page has no cursor', () async {
      expect((await build().ended()).nextCursor, isNull);
    });

    test('does not follow a page address on another server', () {
      answer = (_) => jsonBody(
        200,
        pageJson([sessionJson()], next: 'https://elsewhere.example/x?cursor=a'),
      );

      expect(build().ended(), throwsA(isA<ServerException>()));
    });
  });

  group('end', () {
    test('deletes the session of another device', () async {
      answer = (_) => jsonBody(204);

      await build().end('abc');

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().path, '/api/v1/auth/sessions/abc/');
    });

    test('one that is already gone is ended', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      await build().end('abc');
    });

    test('a 404 that is not the documented one is a failure', () {
      answer = (_) => jsonBody(404);

      expect(build().end('abc'), throwsA(isA<ServerException>()));
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().end('abc'), throwsA(isA<NoConnectionException>()));
    });
  });

  group('endOthers', () {
    test('sends the password as typed and reads what was done', () async {
      answer = (_) => jsonBody(200, {'ended': 2, 'device_keys_removed': 3});

      final result = await build().endOthers(password: ' My Pass ');

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/api/v1/auth/sessions/revoke-others/');
      expect(lastRequest().data, {'current_password': ' My Pass '});
      expect(result, const OthersSignedOut(sessionsEnded: 2, keysRemoved: 3));
    });

    test('a wrong password is a refusal', () {
      answer = (_) => jsonBody(
        400,
        errorBody('invalid_password', attr: 'current_password'),
      );

      expect(
        build().endOthers(password: 'nope'),
        throwsA(
          isA<SessionRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            SessionRefusal.wrongPassword,
          ),
        ),
      );
    });

    test('too many wrong passwords is a wait with its countdown', () async {
      answer = (_) => jsonBody(429, errorBody('password_attempts_exceeded'), {
        'Retry-After': '900',
      });

      await expectLater(
        build().endOthers(password: 'nope'),
        throwsA(
          isA<TooManyRequestsException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 900),
          ),
        ),
      );
    });

    test('any other 400 is a server failure', () {
      answer = (_) => jsonBody(400, errorBody('something_else'));

      expect(build().endOthers(password: 'x'), throwsA(isA<ServerException>()));
    });
  });

  group('activity', () {
    test('reads the entries a page at a time', () async {
      answer = (_) => jsonBody(
        200,
        pageJson(
          [
            eventJson(
              type: 'data_exported',
              kinds: ['transactions'],
              count: 125,
              sessionId: 's1',
            ),
            eventJson(id: 'two', signInMethod: 'device_key'),
          ],
          next:
              'https://api.example.test/api/v1/auth/session-history/?cursor=zz',
        ),
      );

      final page = await build().activity(cursor: 'c0');

      expect(lastRequest().path, '/api/v1/auth/session-history/');
      expect(lastRequest().uri.queryParameters['cursor'], 'c0');
      expect(page.nextCursor, 'zz');
      final export = page.items.first;
      expect(export.type, SecurityEventType.dataExported);
      expect(export.kinds, ['transactions']);
      expect(export.count, 125);
      expect(export.sessionId, 's1');
      expect(export.deviceName, 'Pixel 8');
      expect(export.platform, SessionPlatform.android);
      expect(page.items.last.signInMethod, SignInMethod.deviceKey);
    });

    test(
      'knows every type, and reads one it does not know as unknown',
      () async {
        const types = {
          'signed_in': SecurityEventType.signedIn,
          'signed_out': SecurityEventType.signedOut,
          'session_revoked': SecurityEventType.sessionRevoked,
          'session_limit_reached': SecurityEventType.sessionLimitReached,
          'password_changed': SecurityEventType.passwordChanged,
          'password_reset': SecurityEventType.passwordReset,
          'email_changed': SecurityEventType.emailChanged,
          'device_key_added': SecurityEventType.deviceKeyAdded,
          'device_key_removed': SecurityEventType.deviceKeyRemoved,
          'token_reuse_detected': SecurityEventType.tokenReuseDetected,
          'data_exported': SecurityEventType.dataExported,
          'data_imported': SecurityEventType.dataImported,
          'brand_new_type': SecurityEventType.unknown,
        };
        answer = (_) => jsonBody(
          200,
          pageJson([for (final type in types.keys) eventJson(type: type)]),
        );

        final page = await build().activity();

        expect(page.items.map((e) => e.type), types.values);
      },
    );

    test('an entry with no device, platform or kinds reads as it is', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          eventJson(
            type: 'password_changed',
            deviceName: null,
            platform: null,
            appVersion: null,
          ),
        ]),
      );

      final event = (await build().activity()).items.single;

      expect(event.deviceName, isNull);
      expect(event.platform, isNull);
      expect(event.kinds, isEmpty);
      expect(event.count, isNull);
    });

    test('a lost connection is "no connection"', () {
      answer = (options) => throw connectionLost(options);

      expect(build().activity(), throwsA(isA<NoConnectionException>()));
    });
  });

  test('has no pushed changes', () async {
    expect(await build().changes.isEmpty, isTrue);
  });
}
