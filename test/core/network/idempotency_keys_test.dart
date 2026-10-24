import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';

import '../../support/fake_clock.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  late FixedClock clock;
  late int made;
  late IdempotencyKeys keys;

  setUp(() {
    clock = FixedClock(DateTime(2026, 10, 25, 9));
    made = 0;
    keys = IdempotencyKeys(clock: clock, newKey: () => 'key-${++made}');
  });

  group('the key of an action', () {
    test('is the same while the action has no answer', () {
      expect(keys.keyFor('add'), 'key-1');
      expect(keys.keyFor('add'), 'key-1');
      expect(keys.isPending('add'), isTrue);
    });

    test('is new after the action got its answer', () {
      keys
        ..keyFor('add')
        ..settle('add');

      expect(keys.isPending('add'), isFalse);
      expect(keys.keyFor('add'), 'key-2');
    });

    test('differs between actions', () {
      expect(keys.keyFor('add a'), isNot(keys.keyFor('add b')));
    });

    test('is dropped after its lifetime, before the server forgets it', () {
      keys.keyFor('add');

      clock.time = clock.time.add(const Duration(hours: 19));
      expect(keys.keyFor('add'), 'key-1');

      clock.time = clock.time.add(const Duration(hours: 2));
      expect(keys.keyFor('add'), 'key-2');
    });

    test('the oldest wait goes when there are too many', () {
      final small =
          IdempotencyKeys(
              clock: clock,
              newKey: () => 'key-${++made}',
              capacity: 2,
            )
            ..keyFor('a')
            ..keyFor('b')
            ..keyFor('c');

      expect(small.isPending('a'), isFalse);
      expect(small.isPending('b'), isTrue);
      expect(small.isPending('c'), isTrue);
    });
  });

  group('run', () {
    Future<String> failWith(
      IdempotencyKeys keys,
      DioException Function(RequestOptions) error,
    ) async {
      String? sent;
      try {
        await keys.run<void>('add', (key) async {
          sent = key;
          throw error(RequestOptions(path: '/x'));
        });
      } on DioException {
        // The failure goes on to the caller; the tests look at the key.
      }
      return sent!;
    }

    test('sends the key and forgets it after a success', () async {
      String? sent;

      final result = await keys.run('add', (key) async {
        sent = key;
        return 42;
      });

      expect(result, 42);
      expect(sent, 'key-1');
      expect(keys.isPending('add'), isFalse);
    });

    test(
      'keeps the key when the connection was lost, so a retry repeats it',
      () async {
        final first = await failWith(
          keys,
          (options) => DioException.connectionError(
            requestOptions: options,
            reason: 'lost',
          ),
        );
        final retry = await keys.run('add', (key) async => key);

        expect(first, 'key-1');
        expect(retry, 'key-1');
      },
    );

    test(
      'keeps the key after a server failure, a busy server, and a wait',
      () async {
        for (final status in [500, 502, 503, 408, 429]) {
          final fresh = IdempotencyKeys(clock: clock, newKey: () => 'k$status');
          await failWith(fresh, (options) => failedCall(status));

          expect(fresh.isPending('add'), isTrue, reason: '$status');
        }
      },
    );

    test('keeps the key while the first try is still running', () async {
      await failWith(
        keys,
        (options) => failedCall(409, {
          'type': 'client_error',
          'errors': [
            {'code': 'idempotency_in_progress', 'detail': 'x'},
          ],
        }),
      );

      expect(keys.isPending('add'), isTrue);
    });

    test('forgets the key after a refusal no retry changes', () async {
      for (final status in [400, 401, 403, 404, 412, 422]) {
        final fresh = IdempotencyKeys(clock: clock, newKey: () => 'k$status');
        await failWith(fresh, (options) => failedCall(status));

        expect(fresh.isPending('add'), isFalse, reason: '$status');
      }
    });

    test('forgets the key after another conflict', () async {
      await failWith(
        keys,
        (options) => failedCall(409, {
          'type': 'client_error',
          'errors': [
            {'code': 'account_has_transactions', 'detail': 'x'},
          ],
        }),
      );

      expect(keys.isPending('add'), isFalse);
    });

    test('passes the failure on as it came', () async {
      await expectLater(
        keys.run<void>('add', (key) async => throw failedCall(412)),
        throwsA(isA<DioException>()),
      );
    });

    test('two presses that each got an answer are two actions', () async {
      final first = await keys.run('add', (key) async => key);
      final second = await keys.run('add', (key) async => key);

      expect(first, isNot(second));
    });
  });

  group('isFinal', () {
    test('no answer at all is not final', () {
      expect(
        IdempotencyKeys.isFinal(const ApiFailure(reachedServer: false)),
        isFalse,
      );
    });

    test('a success status is not a failure to settle', () {
      expect(
        IdempotencyKeys.isFinal(const ApiFailure(statusCode: 200)),
        isFalse,
      );
    });
  });
}
