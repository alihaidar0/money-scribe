import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/code_verification_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

import '../../../support/fake_ticker.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;
  late FakeTicker ticker;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo);
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
    int resendSecondsLeft = 60,
    int attemptsLeft = 0,
  }) {
    return CodeVerificationState(
      email: 'alex@example.com',
      status: status,
      resendSecondsLeft: resendSecondsLeft,
      attemptsLeft: attemptsLeft,
    );
  }

  test('starts with the email the code was sent to', () async {
    await auth.register(name: 'A', email: 'new@b.c', password: 'x');

    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.email, 'new@b.c');
    expect(bloc.state.status, CodeVerificationStatus.entering);
    expect(bloc.state.resendSecondsLeft, 60);
  });

  group('CodeSubmitted', () {
    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'verifies a correct code',
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('1234')),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.verified),
      ],
      verify: (_) => expect(auth.isSignedIn, isTrue),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'a reset code does not sign in',
      build: () => build(purpose: CodePurpose.resetPassword),
      act: (bloc) => bloc.add(const CodeSubmitted('1234')),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.verified),
      ],
      verify: (_) => expect(auth.isSignedIn, isFalse),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'ignores a code that is not complete',
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('12')),
      expect: () => <CodeVerificationState>[],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'shows a wrong code with the tries left',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.wrong)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('4817')),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.wrong, attemptsLeft: 2),
      ],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'shows an expired code',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.expired)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('4817')),
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
        bloc.add(const CodeSubmitted('4817'));
        await pumpEventQueue();
        demo.update(const DemoSettings());
        bloc.add(const CodeSubmitted('4817'));
      },
      skip: 2,
      expect: () => <CodeVerificationState>[],
      verify: (_) => expect(auth.isSignedIn, isFalse),
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const CodeSubmitted('4817')),
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
      act: (bloc) => bloc.add(const CodeSubmitted('4817')),
      expect: () => [
        state(CodeVerificationStatus.verifying),
        state(CodeVerificationStatus.failure),
      ],
      errors: () => [isA<ServerException>()],
    );
  });

  group('CodeEdited', () {
    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'clears a wrong code error',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.wrong)),
      build: build,
      act: (bloc) async {
        bloc.add(const CodeSubmitted('4817'));
        await pumpEventQueue();
        bloc.add(const CodeEdited());
      },
      skip: 2,
      expect: () => [state(CodeVerificationStatus.entering, attemptsLeft: 2)],
    );

    blocTest<CodeVerificationBloc, CodeVerificationState>(
      'changes nothing while entering',
      build: build,
      act: (bloc) => bloc.add(const CodeEdited()),
      expect: () => <CodeVerificationState>[],
    );
  });

  group('the wait for a new code', () {
    test('starts at 60 seconds and counts down', () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(const CodeVerificationStarted());
      await pumpEventQueue();
      ticker.tick(41);
      await pumpEventQueue();

      expect(ticker.started, [60]);
      expect(bloc.state.resendSecondsLeft, 41);
    });

    test('cannot resend before it ends', () async {
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const CodeVerificationStarted());
      await pumpEventQueue();

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(ticker.started, [60]);
    });

    test('resends once it ends, and waits again', () async {
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const CodeVerificationStarted());
      await pumpEventQueue();
      ticker.tick(0);
      await pumpEventQueue();
      expect(bloc.state.resendSecondsLeft, 0);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(ticker.started, [60, 60]);
      expect(bloc.state.resendSecondsLeft, 60);
      expect(bloc.state.status, CodeVerificationStatus.entering);
    });

    test('resends after the code expired, even before the wait ends', () async {
      demo.update(const DemoSettings(code: DemoCode.expired));
      final bloc = build();
      addTearDown(bloc.close);
      bloc
        ..add(const CodeVerificationStarted())
        ..add(const CodeSubmitted('4817'));
      await pumpEventQueue();
      expect(bloc.state.status, CodeVerificationStatus.expired);

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(bloc.state.status, CodeVerificationStatus.entering);
      expect(ticker.started, [60, 60]);
    });

    test('a failed resend is reported', () async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(const CodeVerificationStarted());
      await pumpEventQueue();
      ticker.tick(0);
      await pumpEventQueue();

      bloc.add(const CodeResendRequested());
      await pumpEventQueue();

      expect(bloc.state.status, CodeVerificationStatus.noConnection);
    });
  });
}
