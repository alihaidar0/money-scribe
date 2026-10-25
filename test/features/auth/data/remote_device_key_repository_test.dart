import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/network/token_store.dart';
import 'package:money_scribe/features/auth/data/remote/remote_auth.dart';
import 'package:money_scribe/features/auth/data/remote/remote_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';

import '../../../support/fake_device_key_store.dart';
import '../../../support/fake_http_adapter.dart';
import '../../../support/in_memory_secure_value_store.dart';

const _deviceId = '0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10';

// The account id as the server sends it: lower case, which the registration
// text must carry too.
const _userId = '7d1f6a54-2b3c-4d5e-8f90-a1b2c3d4e5f6';

// 32 bytes, 0 to 31, as the server sends them: base64url without padding.
final List<int> _challengeBytes = List<int>.generate(32, (index) => index);
final String _challenge = base64Url.encode(_challengeBytes).replaceAll('=', '');

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
  @override
  Future<String?> read() async => 'Europe/Berlin';
}

Map<String, Object?> _keyJson({
  String deviceId = _deviceId,
  bool isCurrent = true,
  String platform = 'android',
}) {
  return {
    'id': '0192a000-0000-7000-8000-0000000000bb',
    'device_id': deviceId,
    'device_name': 'Pixel 8',
    'platform': platform,
    'attested': true,
    'is_current': isCurrent,
    'created_at': '2026-10-24T08:00:00Z',
    'last_used_at': null,
    'expires_at': '2026-11-23T08:00:00Z',
  };
}

Map<String, Object?> _signedIn() {
  return {
    'access_token': 'access-2',
    'refresh_token': 'refresh-2',
    'token_type': 'Bearer',
    'expires_in': 600,
    'user': {'id': _userId, 'name': 'Alex', 'email': 'alex@example.com'},
  };
}

void main() {
  late InMemorySecureValueStore secure;
  late TokenStore tokens;
  late FakeDeviceKeyStore store;
  late Map<String, ResponseBody Function(RequestOptions)> routes;
  late FakeHttpAdapter server;
  late RemoteAuth remote;
  late RemoteDeviceKeyRepository keys;

  Map<String, dynamic> bodyOf(String path) {
    return server.requests.lastWhere((r) => r.path == path).data
        as Map<String, dynamic>;
  }

  RequestOptions lastRequest(String path) {
    return server.requests.lastWhere((r) => r.path == path);
  }

  int count(String path, [String? method]) {
    return server.requests
        .where((r) => r.path == path && (method == null || r.method == method))
        .length;
  }

  Future<void> signIn() async {
    await tokens.write(
      const SessionTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    await remote.repository.restore();
  }

  setUp(() {
    secure = InMemorySecureValueStore();
    tokens = SecureTokenStore(secure);
    store = FakeDeviceKeyStore();
    routes = {
      '/api/v1/auth/profile/': (_) => jsonBody(200, {
        'id': _userId,
        'name': 'Alex',
        'email': 'alex@example.com',
        'language': 'en',
        'time_zone': 'Europe/Berlin',
      }),
      '/api/v1/auth/device-keys/challenge/': (_) => jsonBody(200, {
        'challenge_id': '0192a000-0000-7000-8000-0000000000aa',
        'challenge': _challenge,
        'expires_in': 120,
      }),
    };
    server = FakeHttpAdapter(
      (options) => (routes[options.path] ?? (_) => jsonBody(404))(options),
    );
    remote = RemoteAuth.create(
      config: ApiConfig.parse('https://api.test', allowCleartext: false)!,
      tokens: tokens,
      device: _Device(),
      timeZone: _Zone(),
      language: () => 'ar',
      deviceKeyStore: store,
      secureStore: secure,
      httpAdapter: server,
    );
    keys = remote.deviceKeys;
  });

  group('turning it on', () {
    setUp(() async {
      await signIn();
      routes['/api/v1/auth/device-keys/current/'] = (_) =>
          jsonBody(201, _keyJson());
    });

    test('registers the key with a proof that the phone holds it', () async {
      await keys.enable(password: '  a pass phrase ', prompt: 'Confirm');

      expect(bodyOf('/api/v1/auth/device-keys/challenge/'), {
        'device_id': _deviceId,
      });
      // The key is made with the 32 raw bytes of the challenge.
      expect(store.challenges.single, _challengeBytes);
      // The proof is the registration text, signed with the fingerprint.
      expect(
        store.signed.single,
        [
          'money-scribe/device-key-registration/v1',
          '0192a000-0000-7000-8000-0000000000aa',
          _challenge,
          _deviceId,
          _userId,
        ].join('\n'),
      );
      expect(store.prompts.single, 'Confirm');
      expect(bodyOf('/api/v1/auth/device-keys/current/'), {
        // Sent as typed: never trimmed.
        'current_password': '  a pass phrase ',
        'public_key': 'public-key-1',
        'algorithm': 'ES256',
        'challenge_id': '0192a000-0000-7000-8000-0000000000aa',
        'signature': 'signature-1',
        'attestation_chain': ['certificate-1', 'certificate-2'],
      });
      expect(lastRequest('/api/v1/auth/device-keys/current/').method, 'PUT');
    });

    test(
      'asks for the challenge without a token, and registers with one',
      () async {
        await keys.enable(password: 'p', prompt: 'Confirm');

        expect(
          lastRequest('/api/v1/auth/device-keys/challenge/')
              .headers['Authorization'],
          isNull,
        );
        expect(
          lastRequest('/api/v1/auth/device-keys/current/')
              .headers['Authorization'],
          'Bearer access-1',
        );
      },
    );

    test('leaves out the chain where the system has no attestation', () async {
      store.attests = false;

      await keys.enable(password: 'p', prompt: 'Confirm');

      expect(
        bodyOf('/api/v1/auth/device-keys/current/')
            .containsKey('attestation_chain'),
        isFalse,
      );
    });

    test(
      'keeps the account to show at sign-in, with the email hidden',
      () async {
        await keys.enable(password: 'p', prompt: 'Confirm');

        expect(
          await keys.signInAccount(),
          const FingerprintAccount(
            accountId: _userId,
            name: 'Alex',
            maskedEmail: 'a***@example.com',
          ),
        );
        expect(await keys.isEnabled(), isTrue);
        // The email itself is never kept next to the key.
        expect(secure.values.values.join(), isNot(contains('alex@')));
      },
    );

    test('a wrong password leaves nothing behind', () async {
      routes['/api/v1/auth/device-keys/current/'] = (_) => jsonBody(
        400,
        errorBody('invalid_password', attr: 'current_password'),
      );

      await expectLater(
        keys.enable(password: 'wrong', prompt: 'Confirm'),
        throwsA(isA<WrongCredentialsException>()),
      );

      expect(store.hasKey, isFalse);
      expect(await keys.isEnabled(), isFalse);
      expect(await keys.signInAccount(), isNull);
    });

    test('a key the server cannot vouch for is refused and deleted', () async {
      routes['/api/v1/auth/device-keys/current/'] = (_) => jsonBody(
        400,
        errorBody('attestation_invalid', attr: 'attestation_chain'),
      );

      await expectLater(
        keys.enable(password: 'p', prompt: 'Confirm'),
        throwsA(
          isA<FingerprintRefusedException>().having(
            (e) => e.reason,
            'reason',
            FingerprintRefusal.attestation,
          ),
        ),
      );

      expect(store.hasKey, isFalse);
    });

    test('says when the account has five phones already', () async {
      routes['/api/v1/auth/device-keys/current/'] = (_) =>
          jsonBody(409, errorBody('device_key_limit_reached'));

      await expectLater(
        keys.enable(password: 'p', prompt: 'Confirm'),
        throwsA(
          isA<FingerprintRefusedException>().having(
            (e) => e.reason,
            'reason',
            FingerprintRefusal.limitReached,
          ),
        ),
      );
    });

    test('says when the challenge ran out', () async {
      routes['/api/v1/auth/device-keys/current/'] = (_) =>
          jsonBody(400, errorBody('challenge_invalid', attr: 'challenge_id'));

      await expectLater(
        keys.enable(password: 'p', prompt: 'Confirm'),
        throwsA(
          isA<FingerprintRefusedException>().having(
            (e) => e.reason,
            'reason',
            FingerprintRefusal.challenge,
          ),
        ),
      );
    });

    test('too many wrong passwords is a wait from the server', () async {
      routes['/api/v1/auth/device-keys/current/'] = (_) => jsonBody(
        429,
        errorBody('password_attempts_exceeded'),
        {'Retry-After': '900'},
      );

      await expectLater(
        keys.enable(password: 'p', prompt: 'Confirm'),
        throwsA(
          isA<RateLimitedException>()
              .having(
                (e) => e.reason,
                'reason',
                RateLimitReason.passwordAttemptsExceeded,
              )
              .having(
                (e) => e.retryAfter,
                'wait',
                const Duration(seconds: 900),
              ),
        ),
      );
      expect(store.hasKey, isFalse);
    });

    test('a fingerprint that is cancelled registers nothing', () async {
      store.signFailure = const FingerprintCancelledException();

      await expectLater(
        keys.enable(password: 'p', prompt: 'Confirm'),
        throwsA(isA<FingerprintCancelledException>()),
      );

      expect(count('/api/v1/auth/device-keys/current/'), 0);
      expect(store.hasKey, isFalse);
    });

    test('a phone that cannot hold the key sends nothing', () async {
      store.supportValue = DeviceKeySupport.notEnrolled;

      await expectLater(
        keys.enable(password: 'p', prompt: 'Confirm'),
        throwsA(isA<FingerprintUnavailableException>()),
      );

      expect(
        server.requests.where((r) => r.path.contains('device-keys')),
        isEmpty,
      );
    });

    test('a lost connection keeps nothing', () async {
      routes['/api/v1/auth/device-keys/current/'] = (options) =>
          throw connectionLost(options);

      await expectLater(
        keys.enable(password: 'p', prompt: 'Confirm'),
        throwsA(isA<NoConnectionException>()),
      );

      expect(store.hasKey, isFalse);
      expect(await keys.isEnabled(), isFalse);
    });
  });

  group('turning it off', () {
    setUp(() async {
      await signIn();
      routes['/api/v1/auth/device-keys/current/'] = (options) =>
          options.method == 'PUT' ? jsonBody(201, _keyJson()) : jsonBody(204);
      await keys.enable(password: 'p', prompt: 'Confirm');
    });

    test('the server forgets the key, then the phone deletes it', () async {
      await keys.disable();

      expect(lastRequest('/api/v1/auth/device-keys/current/').method, 'DELETE');
      expect(store.hasKey, isFalse);
      expect(await keys.isEnabled(), isFalse);
      expect(await keys.signInAccount(), isNull);
    });

    test('the key stays when the server cannot be reached', () async {
      routes['/api/v1/auth/device-keys/current/'] = (options) =>
          throw connectionLost(options);

      await expectLater(keys.disable(), throwsA(isA<NoConnectionException>()));

      expect(store.hasKey, isTrue);
      expect(await keys.isEnabled(), isTrue);
    });
  });

  group('signing in', () {
    setUp(() async {
      await signIn();
      routes['/api/v1/auth/device-keys/current/'] = (options) =>
          options.method == 'PUT' ? jsonBody(201, _keyJson()) : jsonBody(204);
      await keys.enable(password: 'p', prompt: 'Confirm');
      await remote.repository.signOut();
      server.requests.clear();
      store.signed.clear();
      routes['/api/v1/auth/device-keys/sign-in/'] = (_) =>
          jsonBody(200, _signedIn());
    });

    test('signs the challenge and starts the session', () async {
      expect(remote.repository.isSignedIn, isFalse);

      await keys.signIn(prompt: 'Sign in');

      expect(
        store.signed.single,
        [
          'money-scribe/device-sign-in/v1',
          '0192a000-0000-7000-8000-0000000000aa',
          _challenge,
          _deviceId,
        ].join('\n'),
      );
      expect(bodyOf('/api/v1/auth/device-keys/sign-in/'), {
        'challenge_id': '0192a000-0000-7000-8000-0000000000aa',
        'signature': 'signature-1',
        'device': {
          'device_id': _deviceId,
          'device_name': 'Pixel 8',
          'platform': 'android',
          'os_version': '14',
          'app_version': '1.0.0+1',
        },
        'language': 'ar',
        'time_zone': 'Europe/Berlin',
      });
      expect(remote.repository.isSignedIn, isTrue);
      expect(remote.repository.accountId, _userId);
      expect(
        await tokens.read(),
        const SessionTokens(accessToken: 'access-2', refreshToken: 'refresh-2'),
      );
    });

    test('sends no token, and no email or password', () async {
      await keys.signIn(prompt: 'Sign in');

      for (final path in [
        '/api/v1/auth/device-keys/challenge/',
        '/api/v1/auth/device-keys/sign-in/',
      ]) {
        expect(lastRequest(path).headers['Authorization'], isNull);
      }
      final body = bodyOf('/api/v1/auth/device-keys/sign-in/');
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('password'), isFalse);
    });

    test('every refusal is one answer, and the key stays', () async {
      routes['/api/v1/auth/device-keys/sign-in/'] = (_) =>
          jsonBody(401, errorBody('device_sign_in_failed'));

      await expectLater(
        keys.signIn(prompt: 'Sign in'),
        throwsA(
          isA<FingerprintRefusedException>().having(
            (e) => e.reason,
            'reason',
            FingerprintRefusal.signInFailed,
          ),
        ),
      );

      expect(remote.repository.isSignedIn, isFalse);
      expect(store.hasKey, isTrue);
      expect(await keys.signInAccount(), isNotNull);
    });

    test('its own lock is a wait from the server', () async {
      routes['/api/v1/auth/device-keys/sign-in/'] = (_) =>
          jsonBody(429, errorBody('sign_in_locked'), {'Retry-After': '600'});

      await expectLater(
        keys.signIn(prompt: 'Sign in'),
        throwsA(
          isA<RateLimitedException>()
              .having((e) => e.reason, 'reason', RateLimitReason.signInLocked)
              .having(
                (e) => e.retryAfter,
                'wait',
                const Duration(seconds: 600),
              ),
        ),
      );
      // The lock of the password sign-in is another lock.
      expect(remote.repository.signInLockRemaining, isNull);
    });

    test('a fingerprint that does not match sends nothing', () async {
      store.signFailure = const FingerprintCancelledException();

      await expectLater(
        keys.signIn(prompt: 'Sign in'),
        throwsA(isA<FingerprintCancelledException>()),
      );

      expect(count('/api/v1/auth/device-keys/sign-in/'), 0);
      expect(store.hasKey, isFalse);
    });

    test('a key the system ended is forgotten', () async {
      store.signFailure = const FingerprintKeyInvalidatedException();

      await expectLater(
        keys.signIn(prompt: 'Sign in'),
        throwsA(isA<FingerprintKeyInvalidatedException>()),
      );

      expect(await keys.signInAccount(), isNull);
    });

    test('without a key it is refused at once', () async {
      store.hasKey = false;
      await keys.signInAccount();
      server.requests.clear();

      await expectLater(
        keys.signIn(prompt: 'Sign in'),
        throwsA(isA<FingerprintRefusedException>()),
      );

      expect(server.requests, isEmpty);
    });
  });

  group('comparing with the server', () {
    setUp(() async {
      await signIn();
      routes['/api/v1/auth/device-keys/current/'] = (options) =>
          options.method == 'PUT' ? jsonBody(201, _keyJson()) : jsonBody(204);
      await keys.enable(password: 'p', prompt: 'Confirm');
      server.requests.clear();
    });

    void serverHas(List<Map<String, Object?>> entries) {
      routes['/api/v1/auth/device-keys/'] = (_) =>
          jsonBody(200, {'next': null, 'previous': null, 'results': entries});
    }

    test('keeps a key the server still knows', () async {
      serverHas([_keyJson()]);

      await keys.sync();

      expect(store.hasKey, isTrue);
      expect(await keys.isEnabled(), isTrue);
    });

    test('lets go of a key the server no longer knows', () async {
      serverHas([_keyJson(isCurrent: false, deviceId: 'another-phone')]);

      await keys.sync();

      expect(store.hasKey, isFalse);
      expect(await keys.isEnabled(), isFalse);
      expect(await keys.signInAccount(), isNull);
    });

    test('takes a key off the server that the phone cannot use', () async {
      store.hasKey = false;
      serverHas([_keyJson()]);

      await keys.sync();

      expect(lastRequest('/api/v1/auth/device-keys/current/').method, 'DELETE');
      expect(await keys.signInAccount(), isNull);
    });

    test('forgets the key of another account', () async {
      routes['/api/v1/auth/profile/'] = (_) => jsonBody(200, {
        'id': 'aaaaaaaa-2b3c-4d5e-8f90-a1b2c3d4e5f6',
        'name': 'Sam',
        'email': 'sam@example.com',
        'language': 'en',
        'time_zone': 'Europe/Berlin',
      });
      await remote.repository.profile();
      serverHas([]);

      await keys.sync();

      expect(store.hasKey, isFalse);
      expect(await keys.signInAccount(), isNull);
    });

    test('leaves everything alone when the server cannot be reached', () async {
      routes['/api/v1/auth/device-keys/'] = (options) =>
          throw connectionLost(options);

      await keys.sync();

      expect(store.hasKey, isTrue);
      expect(await keys.isEnabled(), isTrue);
    });

    test('asks nothing while nobody is signed in', () async {
      await remote.repository.signOut();
      server.requests.clear();

      await keys.sync();

      expect(server.requests, isEmpty);
      expect(store.hasKey, isTrue);
    });
  });

  group('an account that is gone', () {
    setUp(() async {
      await signIn();
      routes['/api/v1/auth/device-keys/current/'] = (_) =>
          jsonBody(201, _keyJson());
      await keys.enable(password: 'p', prompt: 'Confirm');
      server.requests.clear();
    });

    test('has its key and its label deleted, telling no one', () async {
      await keys.forgetLocal();

      expect(store.hasKey, isFalse);
      expect(await keys.signInAccount(), isNull);
      expect(server.requests, isEmpty);
    });

    test('tells the screens that the key is gone', () async {
      var announced = 0;
      final listening = keys.changes.listen((_) => announced++);

      await keys.forgetLocal();
      await pumpEventQueue();
      await listening.cancel();

      expect(announced, 1);
    });
  });

  group('the phones', () {
    setUp(signIn);

    test('are listed, the web never being one of them', () async {
      routes['/api/v1/auth/device-keys/'] = (_) => jsonBody(200, {
        'next': null,
        'previous': null,
        'results': [
          _keyJson(),
          _keyJson(
            deviceId: 'b1c2d3e4-0000-4000-8000-000000000001',
            isCurrent: false,
            platform: 'ios',
          ),
          _keyJson(deviceId: 'web', isCurrent: false, platform: 'web'),
        ],
      });

      final entries = await keys.keys();

      expect(entries, hasLength(2));
      expect(entries.first.isCurrent, isTrue);
      expect(entries.last.platform, DevicePlatform.ios);
      expect(entries.first.lastUsedAt, isNull);
      expect(entries.first.expiresAt, DateTime.utc(2026, 11, 23, 8));
    });

    test('one is removed by its id in lower case', () async {
      routes['/api/v1/auth/device-keys/b1c2d3e4-0000-4000-8000-000000000001/'] =
          (_) => jsonBody(204);

      await keys.removeKey('B1C2D3E4-0000-4000-8000-000000000001');

      expect(
        lastRequest(
          '/api/v1/auth/device-keys/b1c2d3e4-0000-4000-8000-000000000001/',
        ).method,
        'DELETE',
      );
    });

    test('one that is already gone is fine', () async {
      // The server answers a plain 404 for an id its route does not match.
      await keys.removeKey('b1c2d3e4-0000-4000-8000-000000000001');
    });

    test('removing this phone deletes its key too', () async {
      store.hasKey = true;
      routes['/api/v1/auth/device-keys/$_deviceId/'] = (_) => jsonBody(204);

      await keys.removeKey(_deviceId);

      expect(store.hasKey, isFalse);
    });
  });
}
