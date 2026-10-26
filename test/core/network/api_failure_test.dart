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

    test('a 412 is a record that changed meanwhile', () {
      expect(
        ApiFailure.from(failedCall(412)).toDataException(),
        isA<StaleRecordException>(),
      );
    });

    test(
      'a first try that is still running is told apart from other conflicts',
      () {
        final running = failedCall(409, {
          'type': 'client_error',
          'errors': [
            {'code': 'idempotency_in_progress', 'detail': 'x'},
          ],
        });
        final other = failedCall(409, {
          'type': 'client_error',
          'errors': [
            {'code': 'account_has_transactions', 'detail': 'x'},
          ],
        });

        expect(
          ApiFailure.from(running).toDataException(),
          isA<RequestInProgressException>(),
        );
        expect(
          ApiFailure.from(other).toDataException(),
          isA<ServerException>(),
        );
      },
    );

    test('any other failed answer is a server failure', () {
      for (final status in [400, 401, 404, 500, 502]) {
        expect(
          ApiFailure.from(failedCall(status)).toDataException(),
          isA<ServerException>(),
          reason: '$status',
        );
      }
    });

    test('a 429 is a wait of the length the server asked for', () {
      final exception = ApiFailure.from(
        failedCall(429, errorBody('throttled'), {'retry-after': '42'}),
      ).toDataException();

      expect(exception, isA<TooManyRequestsException>());
      expect(
        (exception as TooManyRequestsException).retryAfter,
        const Duration(seconds: 42),
      );
    });

    test('a 429 without Retry-After still waits, for a safe default', () {
      final exception = ApiFailure.from(failedCall(429)).toDataException();

      expect(
        (exception as TooManyRequestsException).retryAfter,
        ApiFailure.missingRetryAfter,
      );
    });
  });

  group('the reference of the request', () {
    test('is read from X-Request-ID', () {
      final failure = ApiFailure.from(
        failedCall(500, errorBody('server_error'), {
          'x-request-id': '7c1f0d52-3b8e-4a49-9d1e-5b6a2f0c8e11',
        }),
      );

      expect(failure.requestId, '7c1f0d52-3b8e-4a49-9d1e-5b6a2f0c8e11');
    });

    test('is left out when it is missing or not of the documented form', () {
      for (final value in ['', 'short', 'has spaces in it 123', 'a' * 65]) {
        expect(
          ApiFailure.from(failedCall(500, {}, {'x-request-id': value}))
              .requestId,
          isNull,
          reason: value,
        );
      }
      expect(ApiFailure.from(failedCall(500)).requestId, isNull);
    });

    test('is none when the server was not reached', () {
      final failure = ApiFailure.from(connectionLost(_options));

      expect(failure.requestId, isNull);
    });
  });

  group('a 404', () {
    test('is "gone" only with the documented not_found body', () {
      expect(
        ApiFailure.from(failedCall(404, errorBody('not_found'))).isNotFound,
        isTrue,
      );
      // A page of the platform, or a path the server does not route.
      expect(ApiFailure.from(failedCall(404)).isNotFound, isFalse);
      expect(
        ApiFailure.from(failedCall(404, '<html>Not Found</html>')).isNotFound,
        isFalse,
      );
      expect(
        ApiFailure.from(failedCall(400, errorBody('not_found'))).isNotFound,
        isFalse,
      );
    });
  });
}

final _options = RequestOptions(path: '/x');
