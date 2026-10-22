import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/sign_in_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';

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

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;
  late FakeTicker ticker;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo);
    ticker = FakeTicker();
  });

  SignInBloc build() => SignInBloc(repository: auth, ticker: ticker);

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
      build: () => SignInBloc(repository: _CountingAuth(demo), ticker: ticker),
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
      build: () => SignInBloc(repository: _RefusedAuth(demo), ticker: ticker),
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.wrongCredentials),
      ],
    );

    test('sends nothing again by itself after a refusal', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      final counting = _CountingAuth(demo);
      final bloc = SignInBloc(repository: counting, ticker: ticker);
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
      build: () => SignInBloc(repository: _ThrottledAuth(demo), ticker: ticker),
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.locked, lockSecondsLeft: 17),
      ],
      verify: (_) => expect(ticker.started, [17]),
    );

    blocTest<SignInBloc, SignInState>(
      'rounds a wait up to whole seconds, so it never ends early',
      build: () => SignInBloc(
        repository: _ThrottledAuth(
          demo,
          wait: const Duration(milliseconds: 1200),
        ),
        ticker: ticker,
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
      build: () => SignInBloc(
        repository: FakeAuthRepository(
          demo: DemoController(latency: const Duration(milliseconds: 20)),
        ),
        ticker: ticker,
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
}
