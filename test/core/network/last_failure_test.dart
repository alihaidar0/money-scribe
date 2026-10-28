import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/dio_factory.dart';
import 'package:money_scribe/core/network/last_failure.dart';

import '../../support/fake_clock.dart';
import '../../support/fake_http_adapter.dart';

const _reference = '7c1f0d52-3b8e-4a49-9d1e-5b6a2f0c8e11';

void main() {
  late FixedClock clock;
  late LastFailure note;

  setUp(() {
    clock = FixedClock(DateTime.utc(2026, 10, 26, 9));
    note = LastFailure(clock: clock);
  });

  ApiFailure failure(
    int status, {
    String? requestId = _reference,
    Duration? retryAfter,
  }) => ApiFailure(
    statusCode: status,
    requestId: requestId,
    retryAfter: retryAfter,
  );

  group('LastFailure', () {
    test('has nothing before the first failure', () {
      expect(note.requestId, isNull);
      expect(note.wait, isNull);
    });

    test('remembers the reference of the latest failed answer', () {
      note.record(failure(500));

      expect(note.requestId, _reference);
    });

    test('a newer failure replaces the older one, even with no reference', () {
      note
        ..record(failure(500))
        ..record(failure(502, requestId: null));

      expect(note.requestId, isNull);
    });

    test('a failure that never reached the server leaves no reference', () {
      note
        ..record(failure(500))
        ..record(const ApiFailure(reachedServer: false));

      expect(note.requestId, isNull);
    });

    test('a reference is not shown for ever', () {
      note.record(failure(500));
      clock.time = clock.time.add(
        LastFailure.referenceAge + const Duration(seconds: 1),
      );

      expect(note.requestId, isNull);
    });

    test('a 429 is a wait that runs down with the clock', () {
      note.record(failure(429, retryAfter: const Duration(seconds: 60)));
      expect(note.wait, const Duration(seconds: 60));

      clock.time = clock.time.add(const Duration(seconds: 45));
      expect(note.wait, const Duration(seconds: 15));

      clock.time = clock.time.add(const Duration(seconds: 15));
      expect(note.wait, isNull);
    });

    test('a 429 without Retry-After waits for the safe default', () {
      note.record(failure(429));

      expect(note.wait, ApiFailure.missingRetryAfter);
    });

    test('another failure after a 429 ends its wait', () {
      note
        ..record(failure(429, retryAfter: const Duration(seconds: 60)))
        ..record(failure(500));

      expect(note.wait, isNull);
    });
  });

  group('LastFailureInterceptor', () {
    late FakeHttpAdapter server;
    late ResponseBody Function(RequestOptions options) answer;

    Dio build() {
      return createPlainDio(
        ApiConfig.parse('https://api.example.test', allowCleartext: false)!,
        lastFailure: note,
      )..httpClientAdapter = server;
    }

    setUp(() {
      answer = (_) => jsonBody(200, {});
      server = FakeHttpAdapter((options) => answer(options));
    });

    test('notes the reference of a failed request', () async {
      answer = (_) => jsonBody(500, errorBody('server_error'), {
        'x-request-id': _reference,
      });

      await expectLater(
        build().get<Object?>('/api/v1/settings/'),
        throwsA(isA<DioException>()),
      );

      expect(note.requestId, _reference);
    });

    test('notes the wait of a 429', () async {
      answer = (_) =>
          jsonBody(429, errorBody('throttled'), {'retry-after': '12'});

      await expectLater(
        build().get<Object?>('/api/v1/settings/'),
        throwsA(isA<DioException>()),
      );

      expect(note.wait, const Duration(seconds: 12));
    });

    test('leaves a 401 alone, the session handling answers it', () async {
      answer = (_) => jsonBody(401, errorBody('token_expired'));

      await expectLater(
        build().get<Object?>('/api/v1/settings/'),
        throwsA(isA<DioException>()),
      );

      expect(note.requestId, isNull);
    });

    test('a success notes nothing', () async {
      await build().get<Object?>('/api/v1/settings/');

      expect(note.requestId, isNull);
      expect(note.wait, isNull);
    });
  });
}
