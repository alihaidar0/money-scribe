import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/app_lock_gate.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';

import '../support/fake_clock.dart';
import '../support/instant_app_lock_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FixedClock clock;
  late FakeAuthRepository auth;
  late InstantAppLockRepository repository;
  late AppLockGate gate;

  AppLockGate build({bool locked = false}) {
    final gate = AppLockGate(
      auth: auth,
      repository: repository,
      clock: clock,
      locked: locked,
    );
    addTearDown(gate.dispose);
    return gate;
  }

  setUp(() {
    clock = FixedClock(DateTime(2026, 10, 23, 9));
    auth = FakeAuthRepository(
      demo: DemoController(latency: Duration.zero),
      signedIn: true,
    );
    // A stay of up to a minute is allowed, so the timeouts can be told apart.
    repository = InstantAppLockRepository(pin: '1234')
      ..currentTimeout = LockTimeout.oneMinute;
    gate = build();
  });

  Future<void> leave(AppLockGate gate) async {
    gate
      ..didChangeAppLifecycleState(AppLifecycleState.inactive)
      ..didChangeAppLifecycleState(AppLifecycleState.hidden)
      ..didChangeAppLifecycleState(AppLifecycleState.paused);
    await pumpEventQueue();
  }

  void returnAfter(Duration away) {
    clock.time = clock.time.add(away);
    gate
      ..didChangeAppLifecycleState(AppLifecycleState.inactive)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);
  }

  group('at start', () {
    test('an app told to start locked is locked, and unlock opens it', () {
      final locked = build(locked: true);
      final changes = <bool>[];
      locked.changes.listen(changes.add);

      expect(locked.isLocked, isTrue);
      locked.unlock();

      expect(locked.isLocked, isFalse);
      expect(changes, [false]);
    });

    test('otherwise it is open', () {
      expect(gate.isLocked, isFalse);
    });
  });

  group('after time in the background', () {
    test('a short stay does not lock it', () async {
      await leave(gate);

      returnAfter(const Duration(seconds: 30));

      expect(gate.isLocked, isFalse);
    });

    test('a stay of the timeout or more does', () async {
      await leave(gate);

      returnAfter(const Duration(minutes: 1));

      expect(gate.isLocked, isTrue);
    });

    test('the timeout the person chose is the one used', () async {
      repository.currentTimeout = LockTimeout.fiveMinutes;
      await leave(gate);

      returnAfter(const Duration(minutes: 4));
      expect(gate.isLocked, isFalse);

      await leave(gate);
      returnAfter(const Duration(minutes: 5));
      expect(gate.isLocked, isTrue);
    });

    test('a new lock asks every time the app comes back', () async {
      repository.currentTimeout = LockTimeout.standard;

      await leave(gate);
      returnAfter(const Duration(seconds: 1));

      expect(LockTimeout.standard, LockTimeout.immediately);
      expect(gate.isLocked, isTrue);
    });

    test('with no wait it is locked before the app comes back', () async {
      repository.currentTimeout = LockTimeout.immediately;

      await leave(gate);

      expect(gate.isLocked, isTrue);
    });

    test(
      'a system dialog that only makes the app inactive does not count',
      () async {
        repository.currentTimeout = LockTimeout.immediately;
        gate.didChangeAppLifecycleState(AppLifecycleState.inactive);
        await pumpEventQueue();

        returnAfter(const Duration(hours: 1));

        expect(gate.isLocked, isFalse);
      },
    );

    test('hidden and then paused count from the first of them', () async {
      gate.didChangeAppLifecycleState(AppLifecycleState.hidden);
      await pumpEventQueue();
      clock.time = clock.time.add(const Duration(seconds: 40));
      gate.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();

      returnAfter(const Duration(seconds: 25));

      // 40 + 25 seconds away, not 25.
      expect(gate.isLocked, isTrue);
    });

    test('a coming back with no leaving before it changes nothing', () {
      gate.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(gate.isLocked, isFalse);
    });

    test(
      'an unlocked app counts its time away from the next leaving',
      () async {
        await leave(gate);
        returnAfter(const Duration(minutes: 2));
        expect(gate.isLocked, isTrue);
        gate.unlock();

        await leave(gate);
        returnAfter(const Duration(seconds: 10));

        expect(gate.isLocked, isFalse);
      },
    );
  });

  group('when there is nothing to lock', () {
    test('an app with no lock turned on is never locked', () async {
      repository.pin = null;
      await leave(gate);

      returnAfter(const Duration(days: 1));

      expect(gate.isLocked, isFalse);
    });

    test('nobody signed in means nothing to lock', () async {
      await auth.signOut();
      await leave(gate);

      returnAfter(const Duration(days: 1));

      expect(gate.isLocked, isFalse);
    });
  });

  group('when the person signs out', () {
    test('the lock opens, and the PIN is kept for the next sign-in', () async {
      repository.account = auth.accountId;
      final locked = build(locked: true);

      await auth.signOut();
      await pumpEventQueue();

      expect(locked.isLocked, isFalse);
      expect(repository.pin, '1234');
      expect(repository.disabledCount, 0);
    });

    test('nothing is locked while nobody is signed in', () async {
      await auth.signOut();
      await leave(gate);

      returnAfter(const Duration(days: 1));

      expect(gate.isLocked, isFalse);
    });

    test(
      'signing in again as the same account finds the lock as it was',
      () async {
        repository.account = auth.accountId;
        await auth.signOut();
        await pumpEventQueue();

        await auth.signIn(email: 'alex@example.com', password: 'secret');
        await pumpEventQueue();

        expect(repository.pin, '1234');
        expect(repository.account, auth.accountId);
        // Signing in is not locking: the person just proved who they are.
        expect(gate.isLocked, isFalse);

        await leave(gate);
        returnAfter(const Duration(minutes: 2));
        expect(gate.isLocked, isTrue);
      },
    );

    test('another account signing in starts without the lock', () async {
      repository.account = auth.accountId;
      await auth.signOut();
      await pumpEventQueue();

      await auth.signIn(email: 'dana@example.com', password: 'secret');
      await pumpEventQueue();

      expect(repository.pin, isNull);
      expect(repository.account, isNull);
    });

    test(
      'a new account registered on the phone starts without the lock',
      () async {
        repository.account = auth.accountId;
        await auth.signOut();
        await pumpEventQueue();

        await auth.register(
          name: 'Dana',
          email: 'dana@example.com',
          password: 'a-password-1',
        );
        await auth.verifyCode(CodePurpose.verifyEmail, '123456');
        await pumpEventQueue();

        expect(repository.pin, isNull);
      },
    );

    test(
      'a lock saved before it knew its account takes the first one',
      () async {
        repository.account = null;
        await auth.signOut();
        await pumpEventQueue();

        await auth.signIn(email: 'alex@example.com', password: 'secret');
        await pumpEventQueue();

        expect(repository.pin, '1234');
        expect(repository.account, auth.accountId);
      },
    );

    test('with no lock turned on there is nothing to bind', () async {
      repository.pin = null;
      await auth.signOut();
      await pumpEventQueue();

      await auth.signIn(email: 'alex@example.com', password: 'secret');
      await pumpEventQueue();

      expect(repository.account, isNull);
    });
  });
}
