import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/auth/data/pin_hasher.dart';
import 'package:money_scribe/features/auth/data/secure_app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';

import '../../../support/fake_biometric_authenticator.dart';
import '../../../support/fake_clock.dart';
import '../../../support/in_memory_secure_value_store.dart';

void main() {
  late InMemorySecureValueStore store;
  late FakeBiometricAuthenticator biometrics;
  late FixedClock clock;
  late SecureAppLockRepository lock;

  SecureAppLockRepository build() {
    return SecureAppLockRepository(
      store: store,
      biometrics: biometrics,
      clock: clock,
      hasher: const PinHasher(iterations: 5, useIsolate: false),
    );
  }

  setUp(() {
    store = InMemorySecureValueStore();
    biometrics = FakeBiometricAuthenticator();
    clock = FixedClock(DateTime.utc(2026, 10, 23, 9));
    lock = build();
  });

  Future<List<PinCheck>> wrongPins(int count) async {
    final checks = <PinCheck>[];
    for (var i = 0; i < count; i++) {
      // Every pause is over by the next try.
      clock.time = clock.time.add(const Duration(hours: 1));
      checks.add(await lock.checkPin('0000'));
    }
    return checks;
  }

  group('the PIN', () {
    test('the lock is off until a PIN is saved', () async {
      expect(await lock.isEnabled(), isFalse);

      await lock.savePin('1234');

      expect(await lock.isEnabled(), isTrue);
    });

    test('only a hash is kept, never the PIN', () async {
      await lock.savePin('4821');

      final kept = store.values.entries.map((e) => '${e.key}=${e.value}');
      expect(kept.join(' '), isNot(contains('4821')));
    });

    test('the right PIN is accepted, a wrong one is not', () async {
      await lock.savePin('1234');

      expect(await lock.checkPin('1234'), isA<PinAccepted>());
      expect(await lock.checkPin('4321'), isA<PinWrong>());
    });

    test('with no lock there is nothing to open', () async {
      expect(await lock.checkPin('1234'), isA<PinAccepted>());
    });

    test('a PIN that survives a restart of the app', () async {
      await lock.savePin('1234');

      final restarted = build();

      expect(await restarted.isEnabled(), isTrue);
      expect(await restarted.checkPin('1234'), isA<PinAccepted>());
    });

    test('a stored value that is not a verifier turns the lock off', () async {
      store.values['app_lock.pin'] = 'garbage';

      expect(await lock.isEnabled(), isFalse);
    });
  });

  group('wrong PINs', () {
    setUp(() => lock.savePin('1234'));

    test('the first four start no pause', () async {
      final checks = await wrongPins(4);

      expect(checks, everyElement(isA<PinWrong>()));
      expect(
        checks.whereType<PinWrong>().map((check) => check.delay),
        everyElement(isNull),
      );
      expect(await lock.pinPauseRemaining(), isNull);
    });

    test(
      'the fifth starts a pause of 30 seconds, and nothing is checked in it',
      () async {
        await wrongPins(4);
        clock.time = clock.time.add(const Duration(hours: 1));

        final fifth = await lock.checkPin('0000');
        expect(fifth, isA<PinWrong>());
        expect((fifth as PinWrong).delay, const Duration(seconds: 30));
        expect(await lock.pinPauseRemaining(), const Duration(seconds: 30));

        clock.time = clock.time.add(const Duration(seconds: 10));
        // The right PIN is not even looked at during the pause.
        final during = await lock.checkPin('1234');
        expect(during, isA<PinPaused>());
        expect((during as PinPaused).remaining, const Duration(seconds: 20));

        clock.time = clock.time.add(const Duration(seconds: 21));
        expect(await lock.pinPauseRemaining(), isNull);
        expect(await lock.checkPin('1234'), isA<PinAccepted>());
      },
    );

    test('the pauses grow, and the tenth wrong PIN ends the PIN', () async {
      final checks = await wrongPins(10);

      expect(checks.take(9).whereType<PinWrong>().map((check) => check.delay), [
        null,
        null,
        null,
        null,
        const Duration(seconds: 30),
        const Duration(minutes: 1),
        const Duration(minutes: 5),
        const Duration(minutes: 15),
        const Duration(minutes: 15),
      ]);
      expect(checks.last, isA<PinTooManyFailures>());
    });

    test('after that not even the right PIN opens the app', () async {
      await wrongPins(10);
      clock.time = clock.time.add(const Duration(days: 1));

      expect(await lock.checkPin('1234'), isA<PinTooManyFailures>());
    });

    test('a right PIN starts the count again', () async {
      await wrongPins(4);
      clock.time = clock.time.add(const Duration(hours: 1));
      expect(await lock.checkPin('1234'), isA<PinAccepted>());

      // Four more wrong ones are still no pause.
      final checks = await wrongPins(4);

      expect(
        checks.whereType<PinWrong>().map((check) => check.delay),
        everyElement(isNull),
      );
    });

    test('the pause and the count survive a restart of the app', () async {
      await wrongPins(5);
      clock.time = clock.time.add(const Duration(seconds: 5));

      final restarted = build();

      expect(await restarted.pinPauseRemaining(), const Duration(seconds: 25));
      expect(await restarted.checkPin('1234'), isA<PinPaused>());
    });

    test('a wrong PIN is counted before it is checked', () async {
      // The count is written before the PIN is compared, so ending the app
      // between the two cannot give a free try.
      store.writes.clear();

      await lock.checkPin('0000');

      expect(store.writes.first, 'app_lock.failures');
    });

    test(
      'a clock set back cannot stretch a pause past the longest one',
      () async {
        await wrongPins(9);
        clock.time = DateTime.utc(2020);

        final remaining = await lock.pinPauseRemaining();

        expect(remaining, const Duration(minutes: 15));
      },
    );
  });

  group('the fingerprint', () {
    test('is offered when the device has one', () async {
      expect(await lock.canUseBiometrics(), isTrue);

      biometrics.available = false;
      expect(await lock.canUseBiometrics(), isFalse);
    });

    test('shows the reason, and a match starts the count again', () async {
      await lock.savePin('1234');
      await wrongPins(3);

      final matched = await lock.unlockWithBiometrics(reason: 'Unlock');

      expect(matched, isTrue);
      expect(biometrics.reasons, ['Unlock']);
      expect(store.values.containsKey('app_lock.failures'), isFalse);
    });

    test('a fingerprint that does not match changes nothing', () async {
      await lock.savePin('1234');
      await wrongPins(3);
      biometrics.matches = false;

      final matched = await lock.unlockWithBiometrics(reason: 'Unlock');

      expect(matched, isFalse);
      expect(store.values['app_lock.failures'], '3');
    });
  });

  group('the timeout', () {
    test('starts at one minute', () async {
      expect(await lock.timeout(), LockTimeout.oneMinute);
    });

    test('keeps what was chosen, also after a restart', () async {
      await lock.setTimeout(LockTimeout.fiveMinutes);

      expect(await build().timeout(), LockTimeout.fiveMinutes);
    });

    test('a value that is not a timeout is the standard one', () async {
      store.values['app_lock.timeout'] = 'forever';

      expect(await lock.timeout(), LockTimeout.standard);
    });
  });

  group('turning the lock off', () {
    test('forgets the PIN, the count, the pause and the timeout', () async {
      await lock.savePin('1234');
      await lock.setTimeout(LockTimeout.immediately);
      await wrongPins(5);

      await lock.disable();

      expect(await lock.isEnabled(), isFalse);
      expect(await lock.pinPauseRemaining(), isNull);
      expect(await lock.timeout(), LockTimeout.standard);
      expect(store.values, isEmpty);
    });

    test('a new PIN starts with a clean count', () async {
      await lock.savePin('1234');
      await wrongPins(5);

      await lock.savePin('5678');

      expect(await lock.pinPauseRemaining(), isNull);
      expect(await lock.checkPin('5678'), isA<PinAccepted>());
    });
  });
}
