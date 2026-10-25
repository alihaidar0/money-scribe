import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/sign_in_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';

import '../../../support/fake_ticker.dart';

/// A server that says there are too many requests, without locking the account.
class _ThrottledAuth extends FakeAuthRepository {
  new(DemoController demo, {this.wait = const Duration(seconds: 17)})
    : super(demo: demo);

  final Duration wait;

  @override
  Future<void> signIn({
    required String email,
    required String password,
    String? challengeToken,
  }) {
    throw RateLimitedException(RateLimitReason.throttled, wait);
  }
}

/// A server that refuses the sign-in without naming a field.
class _RefusedAuth extends FakeAuthRepository {
  new(DemoController demo) : super(demo: demo);

  @override
  Future<void> signIn({
    required String email,
    required String password,
    String? challengeToken,
  }) {
    throw const WrongCredentialsException();
  }
}

/// Counts the sign-in requests that reach the server.
class _CountingAuth extends FakeAuthRepository {
  new(DemoController demo) : super(demo: demo);

  int sent = 0;

  @override
  Future<void> signIn({
    required String email,
    required String password,
    String? challengeToken,
  }) {
    sent++;
    return super.signIn(
      email: email,
      password: password,
      challengeToken: challengeToken,
    );
  }
}

/// A phone whose key stopped working: a fingerprint was added, so the phone
/// deletes the key and says so.
class _InvalidatedKeys extends FakeDeviceKeyRepository {
  new({required super.demo, required super.auth});

  @override
  Future<void> signIn({required String prompt}) async {
    await forgetLocal();
    throw const FingerprintKeyInvalidatedException();
  }
}

/// A phone that cannot be asked whether it has a key.
class _UnreadableKeys extends FakeDeviceKeyRepository {
  new({required super.demo, required super.auth});

  @override
  Future<FingerprintAccount?> signInAccount() {
    throw StateError('The secure storage cannot be read');
  }
}

/// Counts the times the fingerprint was asked to sign in.
class _CountingKeys extends FakeDeviceKeyRepository {
  new({required super.demo, required super.auth});

  int signIns = 0;

  @override
  Future<void> signIn({required String prompt}) {
    signIns++;
    return super.signIn(prompt: prompt);
  }
}

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;
  late FakeTicker ticker;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo);
    ticker = FakeTicker();
  });

  /// The Bloc over [account], on a phone with no fingerprint key unless
  /// [keys] is given.
  SignInBloc blocFor(
    FakeAuthRepository account, {
    FakeDeviceKeyRepository? keys,
  }) {
    return SignInBloc(
      repository: account,
      deviceKeys: keys ?? FakeDeviceKeyRepository(demo: demo, auth: account),
      ticker: ticker,
    );
  }

  SignInBloc build() => blocFor(auth);

  const submit = SignInSubmitted(email: 'a@b.c', password: 'x');

  group('SignInSubmitted', () {
    blocTest<SignInBloc, SignInState>(
      'signs in with any email and password',
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.success),
      ],
      verify: (_) => expect(auth.isSignedIn, isTrue),
    );

    blocTest<SignInBloc, SignInState>(
      'names the password when it is wrong',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.wrongPassword),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'names the email when no account has it',
      setUp: () => demo.update(
        const DemoSettings(signIn: DemoSignIn.emailNotRegistered),
      ),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.emailNotRegistered),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'asks for the bot challenge before looking at the email and password',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.challengeRequired)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.challengeRequired),
      ],
      verify: (_) => expect(auth.isSignedIn, isFalse),
    );

    blocTest<SignInBloc, SignInState>(
      'signs in once the challenge is solved and its token is sent',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.challengeRequired)),
      build: build,
      act: (bloc) => bloc.add(
        const SignInSubmitted(
          email: 'a@b.c',
          password: 'x',
          challengeToken: 'token',
        ),
      ),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.success),
      ],
      verify: (_) => expect(auth.isSignedIn, isTrue),
    );

    blocTest<SignInBloc, SignInState>(
      'asks for a new challenge when the token is refused',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.challengeRejected)),
      build: build,
      act: (bloc) => bloc.add(
        const SignInSubmitted(
          email: 'a@b.c',
          password: 'x',
          challengeToken: 'token',
        ),
      ),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.challengeRejected),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'goes back to the form, sending nothing, when the challenge is closed',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.challengeRequired)),
      build: () => blocFor(_CountingAuth(demo)),
      act: (bloc) async {
        bloc.add(submit);
        await pumpEventQueue();
        bloc.add(const SignInChallengeDismissed());
      },
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.challengeRequired),
        SignInState(),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'ignores a closed challenge when none is open',
      build: build,
      act: (bloc) => bloc.add(const SignInChallengeDismissed()),
      expect: () => const <SignInState>[],
    );

    blocTest<SignInBloc, SignInState>(
      'shows a refusal that names no field in a banner',
      build: () => blocFor(_RefusedAuth(demo)),
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.wrongCredentials),
      ],
    );

    test('sends nothing again by itself after a refusal', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      final counting = _CountingAuth(demo);
      final bloc = blocFor(counting);
      addTearDown(bloc.close);

      bloc.add(submit);
      await pumpEventQueue();
      bloc
        ..add(const SignInEmailEdited())
        ..add(const SignInPasswordEdited());
      await pumpEventQueue();

      expect(counting.sent, 1);
    });

    blocTest<SignInBloc, SignInState>(
      'locks at once when the demo says so, and starts the countdown',
      setUp: () => demo.update(const DemoSettings(signIn: DemoSignIn.locked)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.locked, lockSecondsLeft: 300),
      ],
      verify: (_) => expect(ticker.started, [300]),
    );

    blocTest<SignInBloc, SignInState>(
      'locks too when the server only says there are too many requests',
      build: () => blocFor(_ThrottledAuth(demo)),
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.locked, lockSecondsLeft: 17),
      ],
      verify: (_) => expect(ticker.started, [17]),
    );

    blocTest<SignInBloc, SignInState>(
      'rounds a wait up to whole seconds, so it never ends early',
      build: () => blocFor(
        _ThrottledAuth(demo, wait: const Duration(milliseconds: 1200)),
      ),
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.locked, lockSecondsLeft: 2),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'opens the code step when the address is not verified, and sends nothing',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.emailNotVerified)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.emailNotVerified),
      ],
      verify: (_) {
        expect(auth.isSignedIn, isFalse);
        expect(auth.pendingEmail, 'a@b.c');
        expect(auth.resendWaitRemaining, Duration.zero);
      },
    );

    blocTest<SignInBloc, SignInState>(
      'asks to try again shortly when the server is busy',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.unavailable)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.unavailable),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.noConnection),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.failure),
      ],
      errors: () => [isA<ServerException>()],
    );

    blocTest<SignInBloc, SignInState>(
      'ignores a second press while the first is being sent',
      build: () => blocFor(
        FakeAuthRepository(
          demo: DemoController(latency: const Duration(milliseconds: 20)),
        ),
      ),
      act: (bloc) => bloc
        ..add(submit)
        ..add(submit),
      wait: const Duration(milliseconds: 100),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.success),
      ],
    );
  });

  group('editing a field', () {
    Future<SignInBloc> refusedBloc(DemoSignIn outcome) async {
      demo.update(DemoSettings(signIn: outcome));
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(submit);
      await bloc.stream.firstWhere(
        (state) => state.status != SignInStatus.submitting,
      );
      return bloc;
    }

    test('the email clears the message about the email', () async {
      final bloc = await refusedBloc(DemoSignIn.emailNotRegistered);

      bloc.add(const SignInEmailEdited());
      await pumpEventQueue();

      expect(bloc.state, const SignInState());
    });

    test('the email clears the message about the password too', () async {
      final bloc = await refusedBloc(DemoSignIn.wrongPassword);

      bloc.add(const SignInEmailEdited());
      await pumpEventQueue();

      expect(bloc.state, const SignInState());
    });

    test('the password clears the message about the password', () async {
      final bloc = await refusedBloc(DemoSignIn.wrongPassword);

      bloc.add(const SignInPasswordEdited());
      await pumpEventQueue();

      expect(bloc.state, const SignInState());
    });

    test('the password keeps the message about the email', () async {
      final bloc = await refusedBloc(DemoSignIn.emailNotRegistered);

      bloc.add(const SignInPasswordEdited());
      await pumpEventQueue();

      expect(bloc.state.status, SignInStatus.emailNotRegistered);
    });

    test('a field edit does not unlock a locked sign-in', () async {
      final bloc = await refusedBloc(DemoSignIn.locked);

      bloc
        ..add(const SignInEmailEdited())
        ..add(const SignInPasswordEdited());
      await pumpEventQueue();

      expect(bloc.state.status, SignInStatus.locked);
    });
  });

  group('the lock', () {
    Future<SignInBloc> lockedBloc() async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(submit);
      await bloc.stream.firstWhere(
        (state) => state.status == SignInStatus.locked,
      );
      return bloc;
    }

    test('counts down with the ticker', () async {
      final bloc = await lockedBloc();

      ticker.tick(299);
      await pumpEventQueue();

      expect(
        bloc.state,
        const SignInState(status: SignInStatus.locked, lockSecondsLeft: 299),
      );
    });

    test('unlocks when the countdown ends', () async {
      final bloc = await lockedBloc();

      ticker.tick(0);
      await pumpEventQueue();

      expect(bloc.state, const SignInState());
    });

    test('starts locked while the repository is locked, and counts', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      await expectLater(
        auth.signIn(email: 'a', password: 'b'),
        throwsA(anything),
      );

      final bloc = build();
      addTearDown(bloc.close);
      expect(bloc.state.status, SignInStatus.locked);
      expect(bloc.state.lockSecondsLeft, 300);

      bloc.add(const SignInStarted());
      await pumpEventQueue();

      expect(ticker.started, [300]);
    });

    test('does nothing at the start when sign-in is not locked', () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const SignInStarted());
      await pumpEventQueue();

      expect(bloc.state, const SignInState());
      expect(ticker.started, isEmpty);
    });
  });

  group('the fingerprint', () {
    /// A matcher for a state with [status], whatever else it holds.
    Matcher state(SignInStatus status, {bool viaFingerprint = false}) {
      return isA<SignInState>()
          .having((s) => s.status, 'status', status)
          .having((s) => s.viaFingerprint, 'viaFingerprint', viaFingerprint);
    }

    /// The account the phone's fingerprint signs in, signed out again.
    Future<(FakeAuthRepository, FakeDeviceKeyRepository)> phoneWithKey([
      FakeDeviceKeyRepository Function(FakeAuthRepository account)? makeKeys,
    ]) async {
      final account = FakeAuthRepository(demo: demo, signedIn: true);
      final keys =
          makeKeys?.call(account) ??
          FakeDeviceKeyRepository(demo: demo, auth: account);
      await keys.enable(password: 'p', prompt: 'Confirm');
      await account.signOut();
      return (account, keys);
    }

    Future<SignInBloc> startedBloc(
      FakeAuthRepository account,
      FakeDeviceKeyRepository keys,
    ) async {
      final bloc = blocFor(account, keys: keys);
      addTearDown(bloc.close);
      bloc.add(const SignInStarted());
      await bloc.stream.firstWhere((s) => s.fingerprintAccount != null);
      return bloc;
    }

    const press = SignInFingerprintRequested(prompt: 'Confirm');

    test('is offered when the phone has a key', () async {
      final (account, keys) = await phoneWithKey();

      final bloc = await startedBloc(account, keys);

      expect(bloc.state.status, SignInStatus.idle);
      expect(
        bloc.state.fingerprintAccount!.maskedEmail,
        endsWith('@example.com'),
      );
      expect(bloc.state.offersFingerprint, isTrue);
    });

    test('is not offered when the phone has no key', () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const SignInStarted());
      await pumpEventQueue();

      expect(bloc.state.fingerprintAccount, isNull);
      expect(bloc.state.offersFingerprint, isFalse);
    });

    test('is not offered when the phone cannot be asked', () async {
      final account = FakeAuthRepository(demo: demo);
      final bloc = blocFor(
        account,
        keys: _UnreadableKeys(demo: demo, auth: account),
      );
      addTearDown(bloc.close);

      bloc.add(const SignInStarted());
      await pumpEventQueue();

      expect(bloc.state.offersFingerprint, isFalse);
      expect(bloc.state.status, SignInStatus.idle);
    });

    test('signs the account in', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);
      final seen = <SignInState>[];
      final listening = bloc.stream.listen(seen.add);

      bloc.add(press);
      await bloc.stream.firstWhere((s) => s.status == SignInStatus.success);
      await listening.cancel();

      expect(account.isSignedIn, isTrue);
      expect(seen, [
        state(SignInStatus.fingerprintSubmitting, viaFingerprint: true),
        state(SignInStatus.success),
      ]);
    });

    test(
      'says nothing when it did not match, and can be tried again',
      () async {
        final (account, keys) = await phoneWithKey();
        final bloc = await startedBloc(account, keys);
        demo.update(
          const DemoSettings(fingerprint: DemoFingerprint.notMatched),
        );

        bloc.add(press);
        await bloc.stream.firstWhere((s) => s.status == SignInStatus.idle);

        expect(bloc.state.offersFingerprint, isTrue);
        expect(account.isSignedIn, isFalse);

        demo.update(const DemoSettings());
        bloc.add(press);
        await bloc.stream.firstWhere((s) => s.status == SignInStatus.success);
      },
    );

    test('keeps the fingerprint when the phone cannot check it now', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.notEnrolled));

      bloc.add(press);
      await bloc.stream.firstWhere(
        (s) => s.status == SignInStatus.fingerprintUnavailable,
      );

      expect(bloc.state.offersFingerprint, isTrue);
      expect(bloc.state.viaFingerprint, isTrue);
    });

    test('goes to the password when the server refuses the key', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);
      demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.signInRefused),
      );

      bloc.add(press);
      await bloc.stream.firstWhere(
        (s) => s.status == SignInStatus.fingerprintRefused,
      );

      expect(bloc.state.offersFingerprint, isFalse);
      expect(bloc.state.usePassword, isTrue);
      expect(account.isSignedIn, isFalse);
    });

    test('forgets the account when the key stopped working', () async {
      final (account, keys) = await phoneWithKey(
        (a) => _InvalidatedKeys(demo: demo, auth: a),
      );
      final bloc = await startedBloc(account, keys);

      bloc.add(press);
      await bloc.stream.firstWhere(
        (s) => s.status == SignInStatus.fingerprintKeyChanged,
      );

      expect(bloc.state.fingerprintAccount, isNull);
      expect(bloc.state.usePassword, isTrue);
      expect(await keys.signInAccount(), isNull);
    });

    test('locks with the countdown the server asked for', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.locked));

      bloc.add(press);
      await bloc.stream.firstWhere((s) => s.status == SignInStatus.locked);

      expect(bloc.state.lockSecondsLeft, 300);
      expect(ticker.started, [300]);
      expect(bloc.state.offersFingerprint, isTrue);
    });

    test('asks to try again shortly when the server is busy', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);
      demo.update(const DemoSettings(fingerprint: DemoFingerprint.unavailable));

      bloc.add(press);
      await bloc.stream.firstWhere((s) => s.status == SignInStatus.unavailable);

      // Try again asks for the fingerprint, not the password.
      expect(bloc.state.viaFingerprint, isTrue);
    });

    test('reports no connection and a server failure', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);

      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      bloc.add(press);
      await bloc.stream.firstWhere(
        (s) => s.status == SignInStatus.noConnection,
      );
      expect(bloc.state.viaFingerprint, isTrue);

      demo.update(const DemoSettings(scenario: DemoScenario.error));
      bloc.add(press);
      await bloc.stream.firstWhere((s) => s.status == SignInStatus.failure);
      expect(bloc.state.viaFingerprint, isTrue);
    });

    test('is asked once when it is pressed twice', () async {
      final slow = DemoController(latency: const Duration(milliseconds: 20));
      final account = FakeAuthRepository(demo: slow, signedIn: true);
      final keys = _CountingKeys(demo: slow, auth: account);
      await keys.enable(password: 'p', prompt: 'Confirm');
      await account.signOut();
      final bloc = await startedBloc(account, keys);

      bloc
        ..add(press)
        ..add(press);
      await bloc.stream.firstWhere((s) => s.status == SignInStatus.success);

      expect(keys.signIns, 1);
    });

    test('does nothing for a phone with no key', () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(press);
      await pumpEventQueue();

      expect(bloc.state, const SignInState());
    });

    test('Use another account shows the form and keeps the key', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);

      bloc.add(const SignInOtherAccountChosen());
      await bloc.stream.firstWhere((s) => s.usePassword);

      expect(bloc.state.offersFingerprint, isFalse);
      expect(bloc.state.fingerprintAccount, isNotNull);
      expect(await keys.signInAccount(), isNotNull);
    });

    test('the password form still signs in, and keeps the choice', () async {
      final (account, keys) = await phoneWithKey();
      final bloc = await startedBloc(account, keys);
      bloc.add(const SignInOtherAccountChosen());
      await bloc.stream.firstWhere((s) => s.usePassword);
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      bloc.add(submit);
      await bloc.stream.firstWhere(
        (s) => s.status == SignInStatus.wrongPassword,
      );

      expect(bloc.state.usePassword, isTrue);
      expect(bloc.state.viaFingerprint, isFalse);
      expect(bloc.state.fingerprintAccount, isNotNull);
    });
  });
}
