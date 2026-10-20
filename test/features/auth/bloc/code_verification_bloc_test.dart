import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/code_verification_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

import '../../../support/fake_ticker.dart';

void main() {
  late DemoController demo;
  late DateTime now;
  late FakeAuthRepository auth;
  late FakeTicker ticker;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    now = DateTime(2026, 10, 11, 9);
    auth = FakeAuthRepository(demo: demo, now: () => now);
    ticker = FakeTicker();
  });

  CodeVerificationBloc build({CodePurpose purpose = CodePurpose.verifyEmail}) {
    return CodeVerificationBloc(
      purpose: purpose,
      repository: auth,
      ticker: ticker,
    );
  }

  CodeVerificationState state(
    CodeVerificationStatus status, {
    int resendSecondsLeft = 0,
    int? attemptsLeft,
    int waitSecondsLeft = 0,
  }) {
    return CodeVerificationState(
      email: 'alex@example.com',
      status: status,
      resendSecondsLeft: resendSecondsLeft,
      attemptsLeft: attemptsLeft,
      waitSecondsLeft: waitSecondsLeft,
    );
  }

  const code = '482915';

  test('starts with the email and the time left to wait', () async {
    await auth.register(name: 'A', email: 'new@b.c', password: 'x');
    now = now.add(const Duration(seconds: 20));

    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.email, 'new@b.c');
    expect(bloc.state.status, CodeVerificationStatus.entering);
    expect(bloc.state.resendSecondsLeft, 40);
  });

  test('a code is six digits long', () {
    expect(CodeVerificationBloc.codeLength, 6);
  });

  test('a new code can be asked for at once when none was requested', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.resendSecondsLeft, 0);
  });

  group('CodeSubmitted', () {
    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'verifies a correct code',
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.verified),
      ],
      verify: (_) => expect(auth.isSignedIn, isTrue),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'a reset code does not sign in',
      build: () => build(purpose: CodePurpose.resetPassword),
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.verified),
      ],
      verify: (_) => expect(auth.isSignedIn, isFalse),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'ignores a code that is not complete',
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('1234')),
      expect: () => <CodeVerificationState>[],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'ignores a code that is too long',
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('1234567')),
      expect: () => <CodeVerificationState>[],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'keeps a leading zero: the code is text',
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('012345')),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.verified),
      ],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'shows a wrong code with the tries left',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.wrong)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.wrong, attemptsLeft: 4),
      ],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'shows a wrong code without a count when the server gives none',
      build: () => CodeVerificationBloc(
        purpose: CodePurpose.verifyEmail,
        repository: _NoCountAuth(demo),
        ticker: ticker,
      ),
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.wrong),
      ],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'shows an expired code',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.expired)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.expired),
      ],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'does not check a code again once it has expired',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.expired)),
      build: build,
      act: (bloc) async {
        bloc.add(const CodeSubmitted(code));
        await pumpEventQueue();
        demo.update(const DemoSettings());
        bloc.add(const CodeSubmitted(code));
      },
      skip: 2,
      expect: () => <CodeVerificationState>[],
      verify: (_) => expect(auth.isSignedIn, isFalse),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'kills the code after too many tries, and waits to ask for a new one',
      setUp: () =>
          demo.update(const DemoSettings(code: DemoCode.attemptsExceeded)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.attemptsExceeded, resendSecondsLeft: 60),
      ],
      verify: (_) => expect(ticker.started, [60]),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'does not check a dead code again',
      setUp: () =>
          demo.update(const DemoSettings(code: DemoCode.attemptsExceeded)),
      build: build,
      act: (bloc) async {
        bloc.add(const CodeSubmitted(code));
        await pumpEventQueue();
        demo.update(const DemoSettings());
        bloc.add(const CodeSubmitted(code));
      },
      skip: 2,
      expect: () => <CodeVerificationState>[],
      verify: (_) => expect(auth.isSignedIn, isFalse),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'asks to try again shortly when the server is busy',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.unavailable)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.unavailable),
      ],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.noConnection),
      ],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted(code)),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.failure),
      ],
      errors: () => [isA<ServerException>()],
    );
  });

  group('when the server says there are too many requests', () {
    Future<CodeVerificationBloc> throttledBloc() async {
      final bloc = CodeVerificationBloc(
        purpose: CodePurpose.verifyEmail,
        repository: _ThrottledAuth(demo),
        ticker: ticker,
      );
      addTearDown(bloc.close);
      bloc.add(const CodeSubmitted(code));
      await bloc.stream.firstWhere(
        (state) => state.status == CodeVerificationStatus.rateLimited,
      );
      return bloc;
    }

    test('the code is not checked until the wait is over', () async {
      final bloc = await throttledBloc();

      expect(bloc.state.waitSecondsLeft, 17);
      expect(ticker.started, [17]);

      ticker.tick(5);
      await pumpEventQueue();
      expect(bloc.state.waitSecondsLeft, 5);

      // A press during the wait does nothing.
      bloc.add(const CodeSubmitted(code));
      await pumpEventQueue();
      expect(bloc.state.status, CodeVerificationStatus.rateLimited);

      ticker.tick(0);
      await pumpEventQueue();
      expect(bloc.state.status, CodeVerificationStatus.entering);
      expect(bloc.state.waitSecondsLeft, 0);
    });
  });

  group('CodeEdited', () {
    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'clears a wrong code error',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.wrong)),
      build: build,
      act: (bloc) async {
        bloc.add(const CodeSubmitted(code));
        await pumpEventQueue();
        bloc.add(const CodeEdited());
      },
      skip: 2,
      expect: () => [state(CodeVerificationStatus.entering, attemptsLeft: 4)],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'clears a busy-server error',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.unavailable)),
      build: build,
      act: (bloc) async {
        bloc.add(const CodeSubmitted(code));
        await pumpEventQueue();
        bloc.add(const CodeEdited());
      },
      skip: 2,
      expect: () => [state(CodeVerificationStatus.entering)],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'changes nothing while entering',
      build: build,
      act: (bloc) => bloc.add(const CodeEdited()),
      expect: () => <CodeVerificationState>[],
    );
  });

  group('the wait for a new code', () {
    Future<CodeVerificationBloc> startedAfterRegister() async {
      await auth.register(name: 'A', email: 'alex@example.com', password: 'x');
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const CodeVerificationStarted());
      await pumpEventQueue();
      return bloc;
    }

    test('is the one the server gave, and counts down', () async {
      final bloc = await startedAfterRegister();

      ticker.tick(41);
      await pumpEventQueue();

      expect(ticker.started, [60]);
      expect(bloc.state.resendSecondsLeft, 41);
    });

    test('is not started when the server asked for none', () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const CodeVerificationStarted());
      await pumpEventQueue();

      expect(ticker.started, isEmpty);
      expect(bloc.state.resendSecondsLeft, 0);
    });

    test('a code can be asked for as soon as the person arrives from '
        'a sign-in with an unverified address', () async {
      demo.update(const DemoSettings(signIn: DemoSignIn.emailNotVerified));
      await expectLater(
        auth.signIn(email: 'late@b.c', password: 'x'),
        throwsA(anything),
      );
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const CodeVerificationStarted());
      await pumpEventQueue();

      expect(bloc.state.email, 'late@b.c');
      expect(bloc.state.resendSecondsLeft, 0);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(bloc.state.resendSecondsLeft, 60);
      expect(ticker.started, [60]);
    });

    test('cannot resend before it ends', () async {
      final bloc = await startedAfterRegister();

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(ticker.started, [60]);
    });

    test('resends once it ends, and waits again', () async {
      final bloc = await startedAfterRegister();
      now = now.add(const Duration(seconds: 60));
      ticker.tick(0);
      await pumpEventQueue();
      expect(bloc.state.resendSecondsLeft, 0);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(ticker.started, [60, 60]);
      expect(bloc.state.resendSecondsLeft, 60);
      expect(bloc.state.status, CodeVerificationStatus.entering);
    });

    test('a new code clears the tries count of the old one', () async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const CodeSubmitted(code));
      await pumpEventQueue();
      expect(bloc.state.attemptsLeft, 4);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(bloc.state.status, CodeVerificationStatus.entering);
      expect(bloc.state.attemptsLeft, isNull);
    });

    test('an expired code waits for the server too', () async {
      await auth.register(name: 'A', email: 'alex@example.com', password: 'x');
      demo.update(const DemoSettings(code: DemoCode.expired));
      final bloc = build();
      addTearDown(bloc.close);
      bloc
        ..add(const CodeVerificationStarted())
        ..add(const CodeSubmitted(code));
      await pumpEventQueue();
      expect(bloc.state.status, CodeVerificationStatus.expired);
      expect(bloc.state.resendSecondsLeft, 60);

      // Pressing resend inside the wait does nothing.
      bloc.add(const CodeResendRequested());
      await pumpEventQueue();
      expect(bloc.state.status, CodeVerificationStatus.expired);
      expect(ticker.started, [60]);

      // Once the wait is over, a new code starts again.
      now = now.add(const Duration(seconds: 60));
      ticker.tick(0);
      await pumpEventQueue();
      bloc.add(const CodeResendRequested());
      await pumpEventQueue();
      expect(bloc.state.status, CodeVerificationStatus.entering);
      expect(ticker.started, [60, 60]);
    });

    test('after too many tries, a new code waits for the time given', () async {
      demo.update(const DemoSettings(code: DemoCode.attemptsExceeded));
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const CodeSubmitted(code));
      await pumpEventQueue();
      expect(bloc.state.status, CodeVerificationStatus.attemptsExceeded);
      expect(bloc.state.resendSecondsLeft, 60);

      now = now.add(const Duration(seconds: 60));
      ticker.tick(0);
      await pumpEventQueue();
      demo.update(const DemoSettings());
      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(bloc.state.status, CodeVerificationStatus.entering);
      expect(bloc.state.resendSecondsLeft, 60);
    });

    test('a refusal to send counts down the time the server gave', () async {
      final bloc = CodeVerificationBloc(
        purpose: CodePurpose.verifyEmail,
        repository: _ResendLimitedAuth(demo),
        ticker: ticker,
      );
      addTearDown(bloc.close);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      // An hour: the countdown is whatever the server said.
      expect(bloc.state.resendSecondsLeft, 3600);
      expect(ticker.started, [3600]);
      expect(bloc.state.status, CodeVerificationStatus.entering);
    });

    test('a busy server is reported when sending', () async {
      demo.update(const DemoSettings(code: DemoCode.unavailable));
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(bloc.state.status, CodeVerificationStatus.unavailable);
    });

    test('a failed resend is reported', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(bloc.state.status, CodeVerificationStatus.noConnection);
    });
  });
}

/// A server that says the code is wrong and does not count the tries.
class _NoCountAuth extends FakeAuthRepository {
  new(DemoController demo) : super(demo: demo);

  @override
  Future<void> verifyCode(CodePurpose purpose, String code) {
    throw const WrongCodeException();
  }
}

/// A server that says there are too many requests.
class _ThrottledAuth extends FakeAuthRepository {
  new(DemoController demo) : super(demo: demo);

  @override
  Future<void> verifyCode(CodePurpose purpose, String code) {
    throw const RateLimitedException(
      RateLimitReason.throttled,
      Duration(seconds: 17),
    );
  }
}

/// A server that has sent too many codes this hour.
class _ResendLimitedAuth extends FakeAuthRepository {
  new(DemoController demo) : super(demo: demo);

  @override
  Future<void> resendCode(CodePurpose purpose) {
    throw const RateLimitedException(
      RateLimitReason.resendLimitReached,
      Duration(hours: 1),
    );
  }
}
