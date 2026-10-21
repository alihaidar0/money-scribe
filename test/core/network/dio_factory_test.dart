import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/network/auth_interceptor.dart';
import 'package:money_scribe/core/network/dio_factory.dart';
import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/network/token_store.dart';

import '../../support/in_memory_secure_value_store.dart';

void main() {
  final config = ApiConfig.parse(
    'https://api.example.com',
    allowCleartext: false,
  )!;

  group('the plain Dio', () {
    test('talks JSON to the server', () {
      final dio = createPlainDio(config);

      expect(dio.options.baseUrl, 'https://api.example.com');
      expect(dio.options.contentType, Headers.jsonContentType);
      expect(dio.options.responseType, ResponseType.json);
      expect(
        dio.options.headers[Headers.acceptHeader],
        Headers.jsonContentType,
      );
    });

    test('is patient with a server that is waking up', () {
      final dio = createPlainDio(config);

      expect(dio.options.connectTimeout, const Duration(seconds: 90));
      expect(dio.options.receiveTimeout, const Duration(seconds: 90));
      expect(dio.options.sendTimeout, const Duration(seconds: 30));
    });

    test('has no session interceptor and no logging', () {
      final interceptors = createPlainDio(config).interceptors;

      expect(interceptors.whereType<AuthInterceptor>(), isEmpty);
      expect(interceptors.whereType<LogInterceptor>(), isEmpty);
    });
  });

  group('the authenticated Dio', () {
    Dio build() {
      return createAuthenticatedDio(
        config: config,
        tokens: SecureTokenStore(InMemorySecureValueStore()),
        refresh: (token) async =>
            const SessionTokens(accessToken: 'a', refreshToken: 'r'),
        needsAuth: (options) => true,
      );
    }

    test('has the session interceptor and nothing that logs', () {
      final interceptors = build().interceptors;

      expect(interceptors.whereType<AuthInterceptor>(), hasLength(1));
      // Requests and answers hold personal and financial data.
      expect(interceptors.whereType<LogInterceptor>(), isEmpty);
    });

    test('shares the settings of the plain one', () {
      final dio = build();

      expect(dio.options.baseUrl, 'https://api.example.com');
      expect(dio.options.connectTimeout, ApiTimeouts.connect);
    });
  });
}
