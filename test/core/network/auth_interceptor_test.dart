import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/auth_interceptor.dart';
import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/network/token_store.dart';

import '../../support/fake_clock.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/in_memory_secure_value_store.dart';

const _old = SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
const _new = SessionTokens(accessToken: 'access-2', refreshToken: 'refresh-2');

void main() {
  late InMemorySecureValueStore secure;
  late TokenStore tokens;
  late FixedClock clock;
  late List<Duration> pauses;
  late List<String?> ended;
  late List<String> refreshedWith;
  late FakeHttpAdapter server;
  late Dio dio;

  /// The access tokens the server accepts. A request with another one gets
  /// `401 token_expired`.
  late Set<String> accepted;

  /// What a refresh does: by default it succeeds with [_new].
  late Future<SessionTokens> Function(String refreshToken) refresh;

  setUp(() async {
    secure = InMemorySecureValueStore();
    tokens = SecureTokenStore(secure);
    await tokens.write(_old);
    secure.writes.clear();
    clock = FixedClock(DateTime(2026, 10, 21, 9));
    pauses = [];
    ended = [];
    refreshedWith = [];
    accepted = {'access-1'};
    refresh = (token) async {
      refreshedWith.add(token);
      accepted.add('access-2');
      return _new;
    };
    server = FakeHttpAdapter((options) {
      final bearer = options.headers['Authorization'];
      if (options.path.startsWith('/public/')) return jsonBody(200);
      if (accepted.any((token) => bearer == 'Bearer $token')) {
        return jsonBody(200, {'bearer': bearer});
      }
      return jsonBody(401, errorBody(AuthInterceptor.tokenExpiredCode));
    });
    dio = _dio(
      server: server,
      tokens: tokens,
      refresh: (token) => refresh(token),
      onEnded: ended.add,
      clock: clock,
      pause: (duration) async {
        pauses.add(duration);
        clock.time = clock.time.add(duration);
      },
    );
  });

  group('the access token', () {
    test('goes with a request that needs it', () async {
      final response = await dio.get<Map<String, dynamic>>('/api/v1/things/');

      expect(response.data, {'bearer': 'Bearer access-1'});
    });

    test('stays off a request that needs none', () async {
      await dio.get<void>('/public/sign-in/');

      expect(server.requests.single.headers['Authorization'], isNull);
    });

    test('is left out when nobody is signed in', () async {
      await tokens.clear();

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(isA<DioException>()),
      );
      expect(server.requests.single.headers['Authorization'], isNull);
      expect(refreshedWith, isEmpty);
    });
  });

  group('an access token that ran out', () {
    setUp(() => accepted = {});

    test(
      'is renewed, and the request is sent again with the new one',
      () async {
        final response = await dio.get<Map<String, dynamic>>('/api/v1/things/');

        expect(response.statusCode, 200);
        expect(response.data, {'bearer': 'Bearer access-2'});
        expect(refreshedWith, ['refresh-1']);
        expect(server.requests, hasLength(2));
      },
    );

    test('stores the new pair before the request is sent again', () async {
      SessionTokens? storedWhenSentAgain;
      server = FakeHttpAdapter((options) async {
        if (options.headers['Authorization'] == 'Bearer access-2') {
          storedWhenSentAgain = await tokens.read();
          return jsonBody(200);
        }
        return jsonBody(401, errorBody(AuthInterceptor.tokenExpiredCode));
      });
      dio = _dio(
        server: server,
        tokens: tokens,
        refresh: (token) async => _new,
        clock: clock,
      );

      await dio.get<void>('/api/v1/things/');

      expect(storedWhenSentAgain, _new);
    });

    test('with several requests at once renews only once', () async {
      final gate = Completer<void>();
      refresh = (token) async {
        refreshedWith.add(token);
        await gate.future;
        accepted.add('access-2');
        return _new;
      };

      final calls = [
        for (var i = 0; i < 4; i++)
          dio.get<Map<String, dynamic>>('/api/v1/t$i/'),
      ];
      await pumpEventQueue();
      gate.complete();
      final responses = await Future.wait(calls);

      expect(refreshedWith, ['refresh-1'], reason: 'one refresh, one token');
      for (final response in responses) {
        expect(response.data, {'bearer': 'Bearer access-2'});
      }
    });

    test('is not renewed again by a request that was sent before the first '
        'renewal and fails after it', () async {
      // The late request carries the old access token, which the server no
      // longer accepts, but the stored pair is already the new one.
      final slowAnswer = Completer<ResponseBody>();
      var firstLateRequest = true;
      server = FakeHttpAdapter((options) {
        final bearer = options.headers['Authorization'];
        if (options.path == '/api/v1/late/' && firstLateRequest) {
          firstLateRequest = false;
          return slowAnswer.future;
        }
        if (bearer == 'Bearer access-2') return jsonBody(200);
        return jsonBody(401, errorBody(AuthInterceptor.tokenExpiredCode));
      });
      dio = _dio(
        server: server,
        tokens: tokens,
        refresh: (token) async {
          refreshedWith.add(token);
          return _new;
        },
        clock: clock,
      );

      final slowCall = dio.get<void>('/api/v1/late/');
      await pumpEventQueue();
      await dio.get<void>('/api/v1/first/'); // renews: access-2 is stored
      slowAnswer.complete(
        jsonBody(401, errorBody(AuthInterceptor.tokenExpiredCode)),
      );
      final response = await slowCall;

      expect(response.statusCode, 200);
      expect(refreshedWith, ['refresh-1'], reason: 'no second refresh');
    });

    test('is renewed again for a later expiry', () async {
      await dio.get<void>('/api/v1/things/');
      accepted = {};
      refresh = (token) async {
        refreshedWith.add(token);
        accepted.add('access-3');
        return const SessionTokens(
          accessToken: 'access-3',
          refreshToken: 'refresh-3',
        );
      };

      await dio.get<void>('/api/v1/things/');

      // The second renewal uses the refresh token of the first one's answer.
      expect(refreshedWith, ['refresh-1', 'refresh-2']);
    });

    test('is sent again only once', () async {
      // Whatever the refresh gives, the server keeps refusing.
      refresh = (token) async {
        refreshedWith.add(token);
        return _new;
      };

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(isA<DioException>()),
      );

      expect(refreshedWith, hasLength(1));
      expect(server.requests, hasLength(2));
    });
  });

  group('a session the server ended', () {
    for (final code in [
      'token_invalid',
      'session_signed_out',
      'session_revoked_by_user',
      'session_password_changed',
      'session_email_changed',
      'session_token_reuse',
      'session_expired',
    ]) {
      test(
        '$code is final: no refresh, tokens cleared, the person told',
        () async {
          server = FakeHttpAdapter((options) => jsonBody(401, errorBody(code)));
          dio = _dio(
            server: server,
            tokens: tokens,
            refresh: (token) => refresh(token),
            onEnded: ended.add,
            clock: clock,
          );

          await expectLater(
            dio.get<void>('/api/v1/things/'),
            throwsA(isA<DioException>()),
          );

          expect(refreshedWith, isEmpty);
          expect(await tokens.read(), isNull);
          expect(ended, [code]);
        },
      );
    }

    test('a 401 with no session on the device ends nothing', () async {
      await tokens.clear();
      server = FakeHttpAdapter(
        (options) => jsonBody(401, errorBody('not_authenticated')),
      );
      dio = _dio(
        server: server,
        tokens: tokens,
        refresh: (token) => refresh(token),
        onEnded: ended.add,
        clock: clock,
      );

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(isA<DioException>()),
      );

      expect(ended, isEmpty);
    });

    test('a wrong password on sign-in is not a session ending', () async {
      server = FakeHttpAdapter(
        (options) => jsonBody(401, errorBody('invalid_credentials')),
      );
      dio = _dio(
        server: server,
        tokens: tokens,
        refresh: (token) => refresh(token),
        onEnded: ended.add,
        clock: clock,
      );

      await expectLater(
        dio.get<void>('/public/sign-in/'),
        throwsA(isA<DioException>()),
      );

      expect(await tokens.read(), _old);
      expect(ended, isEmpty);
    });
  });

  group('a refresh the server refuses', () {
    setUp(() => accepted = {});

    test('with a 401 ends the session and reports that answer', () async {
      refresh = (token) async {
        refreshedWith.add(token);
        throw failedCall(401, errorBody('session_expired'));
      };

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'status',
            401,
          ),
        ),
      );

      expect(await tokens.read(), isNull);
      expect(ended, ['session_expired']);
      expect(refreshedWith, ['refresh-1']);
    });

    test('with a 400 keeps the tokens, and does not try again', () async {
      refresh = (token) async {
        refreshedWith.add(token);
        throw failedCall(400, errorBody('invalid', type: 'validation_error'));
      };

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(isA<DioException>()),
      );

      expect(await tokens.read(), _old);
      expect(ended, isEmpty);
      expect(refreshedWith, hasLength(1));
      expect(pauses, isEmpty);
    });
  });

  group('a refresh whose answer is lost', () {
    setUp(() => accepted = {});

    test('is sent again with the same refresh token, and succeeds', () async {
      var calls = 0;
      refresh = (token) async {
        refreshedWith.add(token);
        accepted.add('access-2');
        // The server rotated the token but the answer never arrived.
        if (++calls == 1) {
          throw DioException.connectionError(
            requestOptions: RequestOptions(path: '/api/v1/auth/refresh/'),
            reason: 'lost',
          );
        }
        return _new;
      };

      final response = await dio.get<void>('/api/v1/things/');

      expect(response.statusCode, 200);
      expect(refreshedWith, ['refresh-1', 'refresh-1']);
      expect(pauses, [AuthInterceptor.defaultReplayDelays.first]);
      expect(await tokens.read(), _new);
      expect(ended, isEmpty);
    });

    test('is also sent again after a server error', () async {
      var calls = 0;
      refresh = (token) async {
        refreshedWith.add(token);
        accepted.add('access-2');
        if (++calls == 1) throw failedCall(502);
        return _new;
      };

      await dio.get<void>('/api/v1/things/');

      expect(refreshedWith, ['refresh-1', 'refresh-1']);
    });

    test('keeps the tokens when it never gets through', () async {
      refresh = (token) async {
        refreshedWith.add(token);
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/v1/auth/refresh/'),
          reason: 'offline',
        );
      };

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );

      // One try and the three planned replays, with the planned pauses.
      expect(refreshedWith, hasLength(4));
      expect(pauses, AuthInterceptor.defaultReplayDelays);
      expect(
        await tokens.read(),
        _old,
        reason: 'a bad connection never signs out',
      );
      expect(ended, isEmpty);
    });

    test(
      'stops trying once the 30 seconds of the server are nearly over',
      () async {
        refresh = (token) async {
          refreshedWith.add(token);
          // Each try takes 20 seconds before it fails.
          clock.time = clock.time.add(const Duration(seconds: 20));
          throw DioException.connectionError(
            requestOptions: RequestOptions(path: '/api/v1/auth/refresh/'),
            reason: 'timeout',
          );
        };

        await expectLater(
          dio.get<void>('/api/v1/things/'),
          throwsA(isA<DioException>()),
        );

        // 20 s elapsed + 1 s pause fits the 25 s window; the second try ends at
        // 41 s, so no third try is made with a token the server may refuse.
        expect(refreshedWith, ['refresh-1', 'refresh-1']);
        expect(await tokens.read(), _old);
      },
    );

    test('is tried afresh by the next request that expires', () async {
      var failing = true;
      refresh = (token) async {
        refreshedWith.add(token);
        if (failing) {
          throw failedCall(400, errorBody('invalid', type: 'validation_error'));
        }
        accepted.add('access-2');
        return _new;
      };

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(isA<DioException>()),
      );
      failing = false;
      final response = await dio.get<void>('/api/v1/things/');

      expect(response.statusCode, 200);
      expect(refreshedWith, ['refresh-1', 'refresh-1']);
    });
  });

  group('the secure storage failing', () {
    test('is reported as a failed request, not an uncaught error', () async {
      accepted = {};
      final broken = _BrokenWriteStore(secure);
      dio = _dio(
        server: server,
        tokens: SecureTokenStore(broken),
        refresh: (token) async => _new,
        clock: clock,
      );

      await expectLater(
        dio.get<void>('/api/v1/things/'),
        throwsA(
          isA<DioException>().having(
            (error) => ApiFailure.from(error).toDataException(),
            'reported as',
            isA<ServerException>(),
          ),
        ),
      );
    });
  });
}

Dio _dio({
  required FakeHttpAdapter server,
  required TokenStore tokens,
  required RefreshSession refresh,
  required FixedClock clock,
  SessionEnded? onEnded,
  Future<void> Function(Duration)? pause,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = server;
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokens: tokens,
      refresh: refresh,
      needsAuth: (options) => !options.path.startsWith('/public/'),
      onSessionEnded: onEnded,
      clock: clock,
      pause: pause ?? (duration) async {},
    ),
  );
  return dio;
}

/// A store whose writes fail.
class _BrokenWriteStore extends InMemorySecureValueStore {
  new(InMemorySecureValueStore from) : super(from.values);

  @override
  Future<void> write(String key, String value) {
    throw StateError('The keystore is not available.');
  }
}
