import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/network/slow_request_monitor.dart';
import 'package:money_scribe/core/network/token_store.dart';
import 'package:money_scribe/features/auth/data/remote/remote_auth.dart';
import 'package:money_scribe/features/auth/data/remote/remote_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

import '../../../support/fake_clock.dart';
import '../../../support/fake_http_adapter.dart';
import '../../../support/in_memory_secure_value_store.dart';
import '../../../support/manual_timers.dart';

const _deviceId = '0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10';

class _Device implements DeviceInfoSource {
  @override
  Future<DeviceInfo> read() async => const DeviceInfo(
    deviceId: _deviceId,
    deviceName: 'Pixel 8',
    platform: DevicePlatform.android,
    osVersion: '14',
    appVersion: '1.0.0+1',
  );
}

class _Zone implements TimeZoneSource {
  new(this.zone);

  String? zone;

  @override
  Future<String?> read() async => zone;
}

Map<String, Object?> _signedIn({
  String access = 'access-1',
  String? refresh = 'refresh-1',
}) {
  return {
    'access_token': access,
    'refresh_token': ?refresh,
    'token_type': 'Bearer',
    'expires_in': 600,
    'user': {
      'id': '7d1f6a54-2b3c-4d5e-8f90-a1b2c3d4e5f6',
      'name': 'Alex',
      'email': 'alex@example.com',
    },
  };
}

void main() {
  late InMemorySecureValueStore secure;
  late TokenStore tokens;
  late FixedClock clock;
  late _Zone zone;
  late String language;
  late Map<String, ResponseBody Function(RequestOptions)> routes;
  late FakeHttpAdapter server;
  late RemoteAuth remote;
  late RemoteAuthRepository auth;

  Map<String, dynamic> bodyOf(String path) {
    return server.requests.lastWhere((r) => r.path == path).data
        as Map<String, dynamic>;
  }

  RequestOptions lastRequest(String path) {
    return server.requests.lastWhere((r) => r.path == path);
  }

  setUp(() {
    secure = InMemorySecureValueStore();
    tokens = SecureTokenStore(secure);
    clock = FixedClock(DateTime(2026, 10, 21, 9));
    zone = _Zone('Europe/Berlin');
    language = 'en';
    routes = {};
    server = FakeHttpAdapter(
      (options) => (routes[options.path] ?? (_) => jsonBody(404))(options),
    );
    remote = RemoteAuth.create(
      config: ApiConfig.parse('https://api.test', allowCleartext: false)!,
      tokens: tokens,
      device: _Device(),
      timeZone: zone,
      language: () => language,
      clock: clock,
      httpAdapter: server,
    );
    auth = remote.repository;
  });

  group('sign in', () {
    setUp(
      () => routes['/api/v1/auth/sign-in/'] = (_) => jsonBody(200, _signedIn()),
    );

    test(
      'sends the credentials as typed, with the device, the language and the '
      'time zone',
      () async {
        await auth.signIn(
          email: 'alex@example.com',
          password: '  a pass phrase ',
        );

        expect(bodyOf('/api/v1/auth/sign-in/'), {
          'email': 'alex@example.com',
          'password': '  a pass phrase ',
          'device': {
            'device_id': _deviceId,
            'device_name': 'Pixel 8',
            'platform': 'android',
            'os_version': '14',
            'app_version': '1.0.0+1',
          },
          'language': 'en',
          'time_zone': 'Europe/Berlin',
        });
      },
    );

    test('leaves the time zone out when it cannot be read', () async {
      zone.zone = null;

      await auth.signIn(email: 'a@b.c', password: 'x');

      expect(bodyOf('/api/v1/auth/sign-in/').containsKey('time_zone'), isFalse);
    });

    test('tells the server the language of the app', () async {
      language = 'ar';

      await auth.signIn(email: 'a@b.c', password: 'x');

      expect(bodyOf('/api/v1/auth/sign-in/')['language'], 'ar');
    });

    test('carries no access token', () async {
      await tokens.write(
        const SessionTokens(accessToken: 'old', refreshToken: 'old-refresh'),
      );

      await auth.signIn(email: 'a@b.c', password: 'x');

      expect(
        lastRequest('/api/v1/auth/sign-in/').headers['Authorization'],
        isNull,
      );
    });

    test('keeps the tokens and signs the person in', () async {
      final changes = <bool>[];
      auth.signedInChanges.listen(changes.add);

      await auth.signIn(email: 'a@b.c', password: 'x');

      expect(auth.isSignedIn, isTrue);
      expect(changes, [true]);
      expect(
        await tokens.read(),
        const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
    });

    test('is a failure when the answer has no refresh token', () async {
      routes['/api/v1/auth/sign-in/'] = (_) =>
          jsonBody(200, _signedIn(refresh: null));

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(isA<ServerException>()),
      );

      expect(auth.isSignedIn, isFalse);
      expect(await tokens.read(), isNull);
    });

    test(
      'is a failure when the answer is not what the contract says',
      () async {
        routes['/api/v1/auth/sign-in/'] = (_) =>
            jsonBody(200, {'access_token': 5});

        await expectLater(
          auth.signIn(email: 'a@b.c', password: 'x'),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test('an email without an account is named', () async {
      routes['/api/v1/auth/sign-in/'] = (_) =>
          jsonBody(401, errorBody('email_not_registered', attr: 'email'));

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(isA<EmailNotRegisteredException>()),
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('a wrong password is named', () async {
      routes['/api/v1/auth/sign-in/'] = (_) =>
          jsonBody(401, errorBody('wrong_password', attr: 'password'));

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(isA<WrongPasswordException>()),
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('any other refusal names no field', () async {
      routes['/api/v1/auth/sign-in/'] = (_) =>
          jsonBody(401, errorBody('invalid_credentials'));

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(isA<WrongCredentialsException>()),
      );
      expect(auth.isSignedIn, isFalse);
    });

    test(
      'an address that is not verified opens the code step, with no wait',
      () async {
        routes['/api/v1/auth/sign-in/'] = (_) =>
            jsonBody(403, errorBody('email_not_verified'));

        await expectLater(
          auth.signIn(email: ' late@b.c ', password: 'x'),
          throwsA(isA<EmailNotVerifiedException>()),
        );

        expect(auth.pendingEmail, 'late@b.c');
        expect(auth.resendWaitRemaining, Duration.zero);
      },
    );

    test('a lock comes with the wait the server gave, counted down', () async {
      routes['/api/v1/auth/sign-in/'] = (_) =>
          jsonBody(429, errorBody('sign_in_locked'), {'retry-after': '300'});

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(
          isA<RateLimitedException>()
              .having((e) => e.reason, 'reason', RateLimitReason.signInLocked)
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(minutes: 5),
              ),
        ),
      );

      expect(auth.signInLockRemaining, const Duration(minutes: 5));
      clock.time = clock.time.add(const Duration(minutes: 2));
      expect(auth.signInLockRemaining, const Duration(minutes: 3));
      clock.time = clock.time.add(const Duration(minutes: 3));
      expect(auth.signInLockRemaining, isNull);
    });

    test('too many requests is a wait without a lock', () async {
      routes['/api/v1/auth/sign-in/'] = (_) =>
          jsonBody(429, errorBody('throttled'), {'retry-after': '17'});

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(
          isA<RateLimitedException>()
              .having((e) => e.reason, 'reason', RateLimitReason.throttled)
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(seconds: 17),
              ),
        ),
      );
      expect(auth.signInLockRemaining, isNull);
    });

    test('a 429 with no Retry-After still gets a wait', () async {
      routes['/api/v1/auth/sign-in/'] = (_) =>
          jsonBody(429, errorBody('throttled'));

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(
          isA<RateLimitedException>().having(
            (e) => e.retryAfter > Duration.zero,
            'a wait',
            isTrue,
          ),
        ),
      );
    });

    test('a busy server is reported', () async {
      routes['/api/v1/auth/sign-in/'] = (_) => jsonBody(
        503,
        errorBody('service_unavailable', type: 'server_error'),
        {'retry-after': '5'},
      );

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });

    test('a lost connection is reported', () async {
      routes['/api/v1/auth/sign-in/'] = (options) =>
          throw connectionLost(options);

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(isA<NoConnectionException>()),
      );
    });

    test('any other failure is a server failure', () async {
      routes['/api/v1/auth/sign-in/'] = (_) => jsonBody(500);

      await expectLater(
        auth.signIn(email: 'a@b.c', password: 'x'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('register', () {
    setUp(() {
      routes['/api/v1/auth/register/'] = (_) => jsonBody(201, {
        'email': 'new@b.c',
        'code_expires_in': 600,
        'resend_available_in': 60,
      });
    });

    test('sends the account, the language and the time zone', () async {
      await auth.register(
        name: 'Alex',
        email: 'new@b.c',
        password: ' long pass phrase ',
      );

      expect(bodyOf('/api/v1/auth/register/'), {
        'name': 'Alex',
        'email': 'new@b.c',
        'password': ' long pass phrase ',
        'language': 'en',
        'time_zone': 'Europe/Berlin',
      });
      expect(
        lastRequest('/api/v1/auth/register/').headers['Authorization'],
        isNull,
      );
    });

    test('remembers the address and starts the wait the server gave', () async {
      await auth.register(name: 'A', email: 'new@b.c', password: 'x');

      expect(auth.pendingEmail, 'new@b.c');
      expect(auth.isSignedIn, isFalse);
      expect(auth.resendWaitRemaining, const Duration(seconds: 60));
      clock.time = clock.time.add(const Duration(seconds: 45));
      expect(auth.resendWaitRemaining, const Duration(seconds: 15));
      clock.time = clock.time.add(const Duration(seconds: 15));
      expect(auth.resendWaitRemaining, Duration.zero);
    });

    test('takes the wait from the answer, whatever it is', () async {
      routes['/api/v1/auth/register/'] = (_) => jsonBody(201, {
        'email': 'new@b.c',
        'code_expires_in': 600,
        'resend_available_in': 90,
      });

      await auth.register(name: 'A', email: 'new@b.c', password: 'x');

      expect(auth.resendWaitRemaining, const Duration(seconds: 90));
    });

    test(
      'a password that is too short says how short, from the answer',
      () async {
        routes['/api/v1/auth/register/'] = (_) => jsonBody(
          400,
          errorBody(
            'password_too_short',
            type: 'validation_error',
            attr: 'password',
            extra: {'min_length': 15},
          ),
        );

        await expectLater(
          auth.register(name: 'A', email: 'a@b.c', password: 'x'),
          throwsA(
            isA<RegistrationRejectedException>().having(
              (e) => e.password,
              'password',
              const PasswordProblem(PasswordIssue.tooShort, limit: 15),
            ),
          ),
        );
      },
    );

    for (final entry in {
      'password_too_long': const PasswordProblem(
        PasswordIssue.tooLong,
        limit: 128,
      ),
      'password_too_similar': const PasswordProblem(PasswordIssue.tooSimilar),
      'password_too_common': const PasswordProblem(PasswordIssue.tooCommon),
      'password_compromised': const PasswordProblem(PasswordIssue.compromised),
    }.entries) {
      test('${entry.key} is worded by the app', () async {
        routes['/api/v1/auth/register/'] = (_) => jsonBody(
          400,
          errorBody(
            entry.key,
            type: 'validation_error',
            attr: 'password',
            extra: {'max_length': 128},
          ),
        );

        await expectLater(
          auth.register(name: 'A', email: 'a@b.c', password: 'x'),
          throwsA(
            isA<RegistrationRejectedException>().having(
              (e) => e.password,
              'password',
              entry.value,
            ),
          ),
        );
      });
    }

    test('a reason the app does not know carries the English text', () async {
      routes['/api/v1/auth/register/'] = (_) => jsonBody(
        400,
        errorBody(
          'password_reused',
          type: 'validation_error',
          attr: 'password',
        ),
      );

      await expectLater(
        auth.register(name: 'A', email: 'a@b.c', password: 'x'),
        throwsA(
          isA<RegistrationRejectedException>().having(
            (e) => e.password,
            'password',
            const PasswordProblem(
              PasswordIssue.other,
              detail: 'Text for developers.',
            ),
          ),
        ),
      );
    });

    test(
      'an email that is not an address, and a name that is refused',
      () async {
        routes['/api/v1/auth/register/'] = (_) => jsonBody(400, {
          'type': 'validation_error',
          'errors': [
            {'code': 'invalid', 'detail': 'x', 'attr': 'email'},
            {'code': 'max_length', 'detail': 'x', 'attr': 'name'},
          ],
        });

        await expectLater(
          auth.register(name: 'A', email: 'a', password: 'x'),
          throwsA(
            isA<RegistrationRejectedException>()
                .having((e) => e.emailInvalid, 'emailInvalid', isTrue)
                .having((e) => e.nameInvalid, 'nameInvalid', isTrue)
                .having((e) => e.password, 'password', isNull),
          ),
        );
      },
    );

    test('a 400 that names no field is a server failure', () async {
      routes['/api/v1/auth/register/'] = (_) =>
          jsonBody(400, errorBody('parse_error'));

      await expectLater(
        auth.register(name: 'A', email: 'a@b.c', password: 'x'),
        throwsA(isA<ServerException>()),
      );
    });

    test('the same address again inside the wait is asked to wait', () async {
      routes['/api/v1/auth/register/'] = (_) =>
          jsonBody(429, errorBody('resend_too_soon'), {'retry-after': '41'});

      await expectLater(
        auth.register(name: 'A', email: 'a@b.c', password: 'x'),
        throwsA(
          isA<RateLimitedException>()
              .having((e) => e.reason, 'reason', RateLimitReason.resendTooSoon)
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(seconds: 41),
              ),
        ),
      );
    });

    test('too many codes this hour is a long wait', () async {
      routes['/api/v1/auth/register/'] = (_) => jsonBody(
        429,
        errorBody('resend_limit_reached'),
        {'retry-after': '3000'},
      );

      await expectLater(
        auth.register(name: 'A', email: 'a@b.c', password: 'x'),
        throwsA(
          isA<RateLimitedException>()
              .having(
                (e) => e.reason,
                'reason',
                RateLimitReason.resendLimitReached,
              )
              .having(
                (e) => e.retryAfter,
                'retryAfter',
                const Duration(seconds: 3000),
              ),
        ),
      );
    });
  });

  group('verify email', () {
    setUp(() async {
      routes['/api/v1/auth/register/'] = (_) => jsonBody(201, {
        'email': 'new@b.c',
        'code_expires_in': 600,
        'resend_available_in': 60,
      });
      routes['/api/v1/auth/verify-email/'] = (_) => jsonBody(200, _signedIn());
      await auth.register(name: 'A', email: 'new@b.c', password: 'x');
    });

    test('sends the code as text, with the address and the device', () async {
      await auth.verifyCode(CodePurpose.verifyEmail, '012345');

      expect(bodyOf('/api/v1/auth/verify-email/'), {
        'email': 'new@b.c',
        'code': '012345',
        'device': {
          'device_id': _deviceId,
          'device_name': 'Pixel 8',
          'platform': 'android',
          'os_version': '14',
          'app_version': '1.0.0+1',
        },
        'language': 'en',
        'time_zone': 'Europe/Berlin',
      });
    });

    test(
      'a correct code signs the person in and clears the pending code',
      () async {
        await auth.verifyCode(CodePurpose.verifyEmail, '123456');

        expect(auth.isSignedIn, isTrue);
        expect(
          await tokens.read(),
          const SessionTokens(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
          ),
        );
        expect(auth.pendingEmail, isNull);
        expect(auth.resendWaitRemaining, Duration.zero);
      },
    );

    test('a wrong code says how many tries are left', () async {
      routes['/api/v1/auth/verify-email/'] = (_) => jsonBody(
        400,
        errorBody(
          'code_invalid',
          type: 'validation_error',
          attr: 'code',
          extra: {'attempts_left': 3},
        ),
      );

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '111111'),
        throwsA(
          isA<WrongCodeException>().having((e) => e.attemptsLeft, 'left', 3),
        ),
      );
      expect(auth.isSignedIn, isFalse);
    });

    test('a wrong code with no count is still a wrong code', () async {
      routes['/api/v1/auth/verify-email/'] = (_) => jsonBody(
        400,
        errorBody('invalid', type: 'validation_error', attr: 'code'),
      );

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '111111'),
        throwsA(
          isA<WrongCodeException>().having(
            (e) => e.attemptsLeft,
            'left',
            isNull,
          ),
        ),
      );
    });

    test('a code that ran out, or never existed, is expired', () async {
      routes['/api/v1/auth/verify-email/'] = (_) =>
          jsonBody(400, errorBody('code_expired', type: 'validation_error'));

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '111111'),
        throwsA(isA<CodeExpiredException>()),
      );
    });

    test('too many wrong codes kills the code and starts the wait', () async {
      routes['/api/v1/auth/verify-email/'] = (_) => jsonBody(
        429,
        errorBody('code_attempts_exceeded'),
        {'retry-after': '60'},
      );

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '111111'),
        throwsA(
          isA<RateLimitedException>().having(
            (e) => e.reason,
            'reason',
            RateLimitReason.codeAttemptsExceeded,
          ),
        ),
      );

      expect(auth.resendWaitRemaining, const Duration(seconds: 60));
    });

    test('with no address to verify, the code is expired', () async {
      final fresh = RemoteAuth.create(
        config: ApiConfig.parse('https://api.test', allowCleartext: false)!,
        tokens: tokens,
        device: _Device(),
        timeZone: zone,
        language: () => language,
        httpAdapter: server,
      ).repository;

      await expectLater(
        fresh.verifyCode(CodePurpose.verifyEmail, '123456'),
        throwsA(isA<CodeExpiredException>()),
      );
    });

    test('a busy server is reported', () async {
      routes['/api/v1/auth/verify-email/'] = (_) =>
          jsonBody(503, errorBody('service_unavailable', type: 'server_error'));

      await expectLater(
        auth.verifyCode(CodePurpose.verifyEmail, '123456'),
        throwsA(isA<ServiceUnavailableException>()),
      );
    });
  });

  group('a new code', () {
    setUp(() async {
      routes['/api/v1/auth/register/'] = (_) => jsonBody(201, {
        'email': 'new@b.c',
        'code_expires_in': 600,
        'resend_available_in': 60,
      });
      routes['/api/v1/auth/resend-code/'] = (_) =>
          jsonBody(200, {'code_expires_in': 600, 'resend_available_in': 60});
      await auth.register(name: 'A', email: 'new@b.c', password: 'x');
      clock.time = clock.time.add(const Duration(seconds: 60));
    });

    test('is asked for the pending address, and starts a new wait', () async {
      await auth.resendCode(CodePurpose.verifyEmail);

      expect(bodyOf('/api/v1/auth/resend-code/'), {'email': 'new@b.c'});
      expect(auth.resendWaitRemaining, const Duration(seconds: 60));
    });

    test('too soon counts down the time the server gave', () async {
      routes['/api/v1/auth/resend-code/'] = (_) =>
          jsonBody(429, errorBody('resend_too_soon'), {'retry-after': '25'});

      await expectLater(
        auth.resendCode(CodePurpose.verifyEmail),
        throwsA(
          isA<RateLimitedException>().having(
            (e) => e.reason,
            'reason',
            RateLimitReason.resendTooSoon,
          ),
        ),
      );

      expect(auth.resendWaitRemaining, const Duration(seconds: 25));
    });

    test(
      'the hourly limit counts down for as long as the server says',
      () async {
        routes['/api/v1/auth/resend-code/'] = (_) => jsonBody(
          429,
          errorBody('resend_limit_reached'),
          {'retry-after': '2700'},
        );

        await expectLater(
          auth.resendCode(CodePurpose.verifyEmail),
          throwsA(isA<RateLimitedException>()),
        );

        expect(auth.resendWaitRemaining, const Duration(minutes: 45));
      },
    );

    test('with no address is expired', () async {
      final fresh = RemoteAuth.create(
        config: ApiConfig.parse('https://api.test', allowCleartext: false)!,
        tokens: tokens,
        device: _Device(),
        timeZone: zone,
        language: () => language,
        httpAdapter: server,
      ).repository;

      await expectLater(
        fresh.resendCode(CodePurpose.verifyEmail),
        throwsA(isA<CodeExpiredException>()),
      );
    });
  });

  group('sign out', () {
    setUp(() async {
      await tokens.write(
        const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      await auth.restore();
      routes['/api/v1/auth/sign-out/'] = (_) => jsonBody(204);
    });

    test('sends the refresh token in the body and no access token', () async {
      await auth.signOut();

      expect(bodyOf('/api/v1/auth/sign-out/'), {'refresh_token': 'refresh-1'});
      expect(
        lastRequest('/api/v1/auth/sign-out/').headers['Authorization'],
        isNull,
      );
    });

    test('clears the tokens and signs the person out', () async {
      final changes = <bool>[];
      auth.signedInChanges.listen(changes.add);

      await auth.signOut();

      expect(await tokens.read(), isNull);
      expect(auth.isSignedIn, isFalse);
      expect(changes, [false]);
    });

    for (final entry in {
      'an already ended session (401)': () =>
          jsonBody(401, errorBody('token_invalid')),
      'a server failure': () => jsonBody(500),
      'a busy server': () =>
          jsonBody(503, errorBody('service_unavailable', type: 'server_error')),
    }.entries) {
      test('signs out here even for ${entry.key}', () async {
        routes['/api/v1/auth/sign-out/'] = (_) => entry.value();

        await auth.signOut();

        expect(await tokens.read(), isNull);
        expect(auth.isSignedIn, isFalse);
      });
    }

    test('signs out here even when there is no connection', () async {
      routes['/api/v1/auth/sign-out/'] = (options) =>
          throw connectionLost(options);

      await auth.signOut();

      expect(await tokens.read(), isNull);
      expect(auth.isSignedIn, isFalse);
    });

    test('with no session sends nothing', () async {
      await tokens.clear();

      await auth.signOut();

      expect(server.requests, isEmpty);
    });
  });

  group('the profile', () {
    setUp(() async {
      await tokens.write(
        const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      await auth.restore();
      routes['/api/v1/auth/profile/'] = (options) {
        if (options.headers['Authorization'] != 'Bearer access-1' &&
            options.headers['Authorization'] != 'Bearer access-2') {
          return jsonBody(401, errorBody('not_authenticated'));
        }
        return jsonBody(200, {
          'id': '7d1f6a54-2b3c-4d5e-8f90-a1b2c3d4e5f6',
          'name': 'Alex',
          'email': 'alex@example.com',
          'language': 'en',
          'time_zone': 'Europe/Berlin',
        });
      };
    });

    test('is read with the access token', () async {
      final profile = await auth.profile();

      expect(profile.name, 'Alex');
      expect(profile.email, 'alex@example.com');
      expect(
        lastRequest('/api/v1/auth/profile/').headers['Authorization'],
        'Bearer access-1',
      );
    });

    test('renews an access token that ran out, then reads it again', () async {
      var expired = true;
      final inner = routes['/api/v1/auth/profile/']!;
      routes['/api/v1/auth/profile/'] = (options) {
        if (expired && options.headers['Authorization'] == 'Bearer access-1') {
          return jsonBody(401, errorBody('token_expired'));
        }
        return inner(options);
      };
      routes['/api/v1/auth/refresh/'] = (_) {
        expired = false;
        return jsonBody(200, {
          'access_token': 'access-2',
          'refresh_token': 'refresh-2',
          'token_type': 'Bearer',
          'expires_in': 600,
        });
      };

      final profile = await auth.profile();

      expect(profile.name, 'Alex');
      expect(bodyOf('/api/v1/auth/refresh/'), {
        'refresh_token': 'refresh-1',
        'device': {
          'device_id': _deviceId,
          'device_name': 'Pixel 8',
          'platform': 'android',
          'os_version': '14',
          'app_version': '1.0.0+1',
        },
      });
      expect(
        await tokens.read(),
        const SessionTokens(accessToken: 'access-2', refreshToken: 'refresh-2'),
      );
      expect(auth.isSignedIn, isTrue);
    });

    test('a session the server ended signs the person out', () async {
      routes['/api/v1/auth/profile/'] = (_) =>
          jsonBody(401, errorBody('session_revoked_by_user'));
      final changes = <bool>[];
      auth.signedInChanges.listen(changes.add);

      await expectLater(auth.profile(), throwsA(isA<DataException>()));

      expect(auth.isSignedIn, isFalse);
      expect(await tokens.read(), isNull);
      expect(changes, [false]);
    });

    test('a refresh the server refuses signs the person out', () async {
      routes['/api/v1/auth/profile/'] = (_) =>
          jsonBody(401, errorBody('token_expired'));
      routes['/api/v1/auth/refresh/'] = (_) =>
          jsonBody(401, errorBody('session_token_reuse'));

      await expectLater(auth.profile(), throwsA(isA<DataException>()));

      expect(auth.isSignedIn, isFalse);
      expect(await tokens.read(), isNull);
    });

    test('a refresh with no connection keeps the person signed in', () async {
      routes['/api/v1/auth/profile/'] = (_) =>
          jsonBody(401, errorBody('token_expired'));
      routes['/api/v1/auth/refresh/'] = (options) =>
          throw connectionLost(options);

      await expectLater(auth.profile(), throwsA(isA<NoConnectionException>()));

      expect(auth.isSignedIn, isTrue);
      expect(
        await tokens.read(),
        const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
    });

    test(
      'a refresh answer without a refresh token keeps the session as it was',
      () async {
        routes['/api/v1/auth/profile/'] = (_) =>
            jsonBody(401, errorBody('token_expired'));
        routes['/api/v1/auth/refresh/'] = (_) => jsonBody(200, {
          'access_token': 'access-2',
          'token_type': 'Bearer',
          'expires_in': 600,
        });

        await expectLater(auth.profile(), throwsA(isA<DataException>()));

        expect(
          await tokens.read(),
          const SessionTokens(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
          ),
        );
      },
    );
  });

  group('the session after a restart', () {
    test('is there when the secure storage has tokens', () async {
      await tokens.write(
        const SessionTokens(accessToken: 'a', refreshToken: 'r'),
      );

      await auth.restore();

      expect(auth.isSignedIn, isTrue);
      expect(server.requests, isEmpty, reason: 'no network to open the app');
    });

    test('is not there when it has none', () async {
      await auth.restore();

      expect(auth.isSignedIn, isFalse);
    });

    test('is checked with the server in the background', () async {
      await tokens.write(
        const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      await auth.restore();
      routes['/api/v1/auth/profile/'] = (_) => jsonBody(200, {
        'id': '7d1f6a54-2b3c-4d5e-8f90-a1b2c3d4e5f6',
        'name': 'Alex',
        'email': 'alex@example.com',
        'language': 'en',
        'time_zone': 'UTC',
      });

      await auth.validateSession();

      expect(auth.isSignedIn, isTrue);
      expect(server.requests.single.path, '/api/v1/auth/profile/');
    });

    test('is kept when the server cannot be reached', () async {
      await tokens.write(
        const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      await auth.restore();
      routes['/api/v1/auth/profile/'] = (options) =>
          throw connectionLost(options);

      await auth.validateSession();

      expect(auth.isSignedIn, isTrue);
    });

    test('ends when the server says the session is over', () async {
      await tokens.write(
        const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
      );
      await auth.restore();
      routes['/api/v1/auth/profile/'] = (_) =>
          jsonBody(401, errorBody('session_expired'));

      await auth.validateSession();

      expect(auth.isSignedIn, isFalse);
      expect(await tokens.read(), isNull);
    });

    test('is not asked about when nobody is signed in', () async {
      await auth.validateSession();

      expect(server.requests, isEmpty);
    });
  });

  group('what the server does not offer yet', () {
    test('says so, without calling the server', () async {
      await expectLater(
        auth.requestPasswordReset('a@b.c'),
        throwsA(isA<FeatureNotAvailableException>()),
      );
      await expectLater(
        auth.resetPassword('x'),
        throwsA(isA<FeatureNotAvailableException>()),
      );
      await expectLater(
        auth.changePassword(current: 'a', next: 'b'),
        throwsA(isA<FeatureNotAvailableException>()),
      );
      await expectLater(
        auth.deleteAccount(password: 'a'),
        throwsA(isA<FeatureNotAvailableException>()),
      );
      await expectLater(
        auth.verifyCode(CodePurpose.resetPassword, '123456'),
        throwsA(isA<FeatureNotAvailableException>()),
      );
      await expectLater(
        auth.resendCode(CodePurpose.resetPassword),
        throwsA(isA<FeatureNotAvailableException>()),
      );

      expect(server.requests, isEmpty);
    });
  });

  group('a server that is slow to answer', () {
    test('is reported to the monitor while a real request waits', () async {
      final timers = ManualTimers();
      final monitor = SlowRequestMonitor(timer: timers.create);
      final answer = Completer<ResponseBody>();
      final slowServer = FakeHttpAdapter((options) => answer.future);
      final slow = RemoteAuth.create(
        config: ApiConfig.parse('https://api.test', allowCleartext: false)!,
        tokens: tokens,
        device: _Device(),
        timeZone: zone,
        language: () => language,
        monitor: monitor,
        httpAdapter: slowServer,
      ).repository;

      final call = slow.signIn(email: 'a@b.c', password: 'x');
      await pumpEventQueue();
      expect(timers.active, hasLength(1));
      expect(monitor.isSlow, isFalse);

      timers.active.single.fire();
      expect(monitor.isSlow, isTrue, reason: 'the server is starting');

      answer.complete(jsonBody(200, _signedIn()));
      await call;
      expect(monitor.isSlow, isFalse);
    });
  });

  test('the whole API of the app sends the token except the auth calls', () {
    for (final path in authPublicPaths) {
      expect(path, startsWith('/api/v1/auth/'));
    }
    expect(authPublicPaths, isNot(contains('/api/v1/auth/profile/')));
    expect(authPublicPaths, hasLength(6));
  });
}
