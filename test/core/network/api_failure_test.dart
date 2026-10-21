import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  group('the error body', () {
    test('is read into its items', () {
      final failure = ApiFailure.from(
        failedCall(400, {
          'type': 'validation_error',
          'errors': [
            {
              'code': 'password_too_short',
              'detail': 'Too short.',
              'attr': 'password',
              'min_length': 15,
            },
            {
              'code': 'invalid',
              'detail': 'Enter a valid email.',
              'attr': 'email',
            },
          ],
        }),
      );

      expect(failure.statusCode, 400);
      expect(failure.items, hasLength(2));
      expect(failure.code, 'password_too_short');
      expect(failure.first?.minLength, 15);
      expect(failure.first?.attr, 'password');
      expect(failure.hasCode('invalid'), isTrue);
      expect(failure.hasCode('code_expired'), isFalse);
      expect(failure.forField('email')?.code, 'invalid');
      expect(failure.forField('name'), isNull);
    });

    test('carries the optional numbers when the server gives them', () {
      final failure = ApiFailure.from(
        failedCall(
          400,
          errorBody(
            'code_invalid',
            type: 'validation_error',
            extra: {'attempts_left': 3},
          ),
        ),
      );

      expect(failure.first?.attemptsLeft, 3);
      expect(failure.first?.minLength, isNull);
      expect(failure.first?.maxLength, isNull);
    });

    test(
      'ignores an item without a code and a number that is not a number',
      () {
        final failure = ApiFailure.from(
          failedCall(400, {
            'errors': [
              {'detail': 'No code here.'},
              {'code': 'code_invalid', 'attempts_left': 'three'},
            ],
          }),
        );

        expect(failure.items, hasLength(1));
        expect(failure.first?.attemptsLeft, isNull);
      },
    );

    test('is empty when the body is not the documented one', () {
      expect(
        ApiFailure.from(failedCall(500, '<html>Server Error</html>')).items,
        isEmpty,
      );
      expect(ApiFailure.from(failedCall(500, null)).items, isEmpty);
      expect(
        ApiFailure.from(failedCall(400, {'errors': 'nope'})).items,
        isEmpty,
      );
    });
  });

  group('Retry-After', () {
    test('is whole seconds', () {
      final failure = ApiFailure.from(
        failedCall(429, errorBody('throttled'), {'retry-after': '120'}),
      );

      expect(failure.retryAfter, const Duration(seconds: 120));
    });

    test('is missing, or ignored when it is not seconds', () {
      expect(ApiFailure.from(failedCall(429)).retryAfter, isNull);
      expect(
        ApiFailure.from(
          failedCall(429, errorBody('throttled'), {'retry-after': 'soon'}),
        ).retryAfter,
        isNull,
      );
      expect(
        ApiFailure.from(
          failedCall(429, errorBody('throttled'), {'retry-after': '-5'}),
        ).retryAfter,
        isNull,
      );
    });
  });

  group('the shared exceptions', () {
    test('a failure with no answer is no connection', () {
      final failure = ApiFailure.from(connectionLost(_options));

      expect(failure.reachedServer, isFalse);
      expect(failure.toDataException(), isA<NoConnectionException>());
    });

    test('a failure that was not the network carries its own cause', () {
      final failure = ApiFailure.from(
        DioException(
          requestOptions: _options,
          error: const ServiceUnavailableException(),
        ),
      );

      expect(failure.toDataException(), isA<ServiceUnavailableException>());
    });

    test('an unknown error with no cause is a lost connection', () {
      final failure = ApiFailure.from(
        DioException(requestOptions: _options, error: StateError('x')),
      );

      expect(failure.toDataException(), isA<NoConnectionException>());
    });

    test('a 503 is a busy server', () {
      expect(
        ApiFailure.from(failedCall(503)).toDataException(),
        isA<ServiceUnavailableException>(),
      );
    });

    test('any other failed answer is a server failure', () {
      for (final status in [400, 401, 404, 429, 500, 502]) {
        expect(
          ApiFailure.from(failedCall(status)).toDataException(),
          isA<ServerException>(),
          reason: '$status',
        );
      }
    });
  });
}

final _options = RequestOptions(path: '/x');
