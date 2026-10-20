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
  Future<void> signIn({required String email, required String password}) {
    throw RateLimitedException(RateLimitReason.throttled, wait);
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
      'shows a wrong password',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword)),
      build: build,
      act: (bloc) => bloc.add(submit),
      expect: () => const [
        SignInState(status: SignInStatus.submitting),
        SignInState(status: SignInStatus.wrongCredentials),
      ],
    );

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
