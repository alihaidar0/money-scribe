import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/forgot_password_bloc.dart';
import 'package:money_scribe/features/auth/bloc/new_password_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

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

  group('ForgotPasswordBloc', () {
    ForgotPasswordBloc build() =>
        ForgotPasswordBloc(repository: auth, ticker: ticker);

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'sends the code and remembers the email',
      build: build,
      act: (bloc) => bloc.add(const ForgotPasswordSubmitted('me@b.c')),
      expect: () => const [
        ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        ForgotPasswordState(status: ForgotPasswordStatus.success),
      ],
      verify: (_) => expect(auth.pendingEmail, 'me@b.c'),
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'asking again at once is a wait the server gave, counted down',
      build: build,
      act: (bloc) async {
        bloc.add(const ForgotPasswordSubmitted('me@b.c'));
        await pumpEventQueue();
        bloc.add(const ForgotPasswordSubmitted('me@b.c'));
        await pumpEventQueue();
        ticker.tick(59);
        await pumpEventQueue();
        ticker.tick(0);
      },
      skip: 2,
      expect: () => const [
        ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        ForgotPasswordState(
          status: ForgotPasswordStatus.waiting,
          waitSecondsLeft: 60,
        ),
        ForgotPasswordState(
          status: ForgotPasswordStatus.waiting,
          waitSecondsLeft: 59,
        ),
        ForgotPasswordState(),
      ],
      verify: (_) => expect(ticker.started, [60]),
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'does not ask while the wait is on',
      build: build,
      seed: () => const ForgotPasswordState(
        status: ForgotPasswordStatus.waiting,
        waitSecondsLeft: 30,
      ),
      act: (bloc) => bloc.add(const ForgotPasswordSubmitted('me@b.c')),
      expect: () => const <ForgotPasswordState>[],
      verify: (_) => expect(auth.pendingEmail, 'alex@example.com'),
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'reports a busy server',
      setUp: () => demo.update(const DemoSettings(code: DemoCode.unavailable)),
      build: build,
      act: (bloc) => bloc.add(const ForgotPasswordSubmitted('me@b.c')),
      expect: () => const [
        ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        ForgotPasswordState(status: ForgotPasswordStatus.unavailable),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const ForgotPasswordSubmitted('me@b.c')),
      expect: () => const [
        ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        ForgotPasswordState(status: ForgotPasswordStatus.noConnection),
      ],
    );

    blocTest<ForgotPasswordBloc, ForgotPasswordState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const ForgotPasswordSubmitted('me@b.c')),
      expect: () => const [
        ForgotPasswordState(status: ForgotPasswordStatus.submitting),
        ForgotPasswordState(status: ForgotPasswordStatus.failure),
      ],
      errors: () => [isA<ServerException>()],
    );
  });

  group('NewPasswordBloc', () {
    NewPasswordBloc build() =>
        NewPasswordBloc(repository: auth, ticker: ticker);

    NewPasswordChanged typed(String password, [String? confirmation]) {
      return NewPasswordChanged(
        password: password,
        confirmation: confirmation ?? password,
      );
    }

    /// Types a matching password, then sends it.
    Future<void> typeAndSave(NewPasswordBloc bloc) async {
      bloc.add(typed('abcdefg1'));
      await pumpEventQueue();
      bloc.add(const NewPasswordSubmitted('abcdefg1'));
    }

    blocTest<NewPasswordBloc, NewPasswordState>(
      'follows whether the two fields are the same text',
      build: build,
      act: (bloc) => bloc
        ..add(typed('abc', ''))
        ..add(typed('abc', 'ab'))
        ..add(typed('abc')),
      expect: () => const [
        NewPasswordState(),
        NewPasswordState(mismatch: true),
        NewPasswordState(matches: true),
      ],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'applies no length or content rule: the server owns them',
      build: build,
      act: (bloc) => bloc.add(typed('x')),
      expect: () => const [NewPasswordState(matches: true)],
      verify: (bloc) => expect(bloc.state.isValid, isTrue),
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'spaces are part of the password: it is never trimmed',
      build: build,
      act: (bloc) => bloc.add(typed(' a ', 'a')),
      expect: () => const [NewPasswordState(mismatch: true)],
    );

    test('empty passwords do not match', () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc
        ..add(typed('abc'))
        ..add(typed(''));
      await pumpEventQueue();

      expect(bloc.state.matches, isFalse);
      expect(bloc.state.isValid, isFalse);
    });

    blocTest<NewPasswordBloc, NewPasswordState>(
      'does not save two fields that differ',
      build: build,
      act: (bloc) => bloc
        ..add(typed('one', 'two'))
        ..add(const NewPasswordSubmitted('one')),
      // Only the typing changes the state: the save is refused.
      expect: () => const [NewPasswordState(mismatch: true)],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'saves a password typed twice and signs the person out',
      setUp: () => auth = FakeAuthRepository(demo: demo, signedIn: true),
      build: build,
      act: typeAndSave,
      skip: 1,
      expect: () => const [
        NewPasswordState(status: NewPasswordStatus.saving, matches: true),
        NewPasswordState(status: NewPasswordStatus.saved, matches: true),
      ],
      verify: (_) => expect(auth.isSignedIn, isFalse),
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'a refused password says why, and typing again clears it',
      setUp: () => demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.passwordRefused),
      ),
      build: build,
      act: (bloc) async {
        await typeAndSave(bloc);
        await pumpEventQueue();
        bloc.add(typed('abcdefg12'));
      },
      skip: 2,
      expect: () => const [
        NewPasswordState(
          status: NewPasswordStatus.rejected,
          matches: true,
          passwordProblem: PasswordProblem(
            PasswordIssue.tooShort,
            limit: FakeAuthRepository.demoMinimumPasswordLength,
          ),
        ),
        NewPasswordState(matches: true),
      ],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'a reset that ran out is reported, to start again',
      setUp: () => demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.tokenInvalid),
      ),
      build: build,
      act: typeAndSave,
      skip: 2,
      expect: () => const [
        NewPasswordState(status: NewPasswordStatus.expired, matches: true),
      ],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'a wait is counted down and the button works again at the end',
      setUp: () => demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.tooSoon),
      ),
      build: build,
      act: (bloc) async {
        await typeAndSave(bloc);
        await pumpEventQueue();
        ticker.tick(29);
        await pumpEventQueue();
        ticker.tick(0);
      },
      skip: 2,
      expect: () => const [
        NewPasswordState(
          status: NewPasswordStatus.waiting,
          matches: true,
          waitSecondsLeft: 30,
        ),
        NewPasswordState(
          status: NewPasswordStatus.waiting,
          matches: true,
          waitSecondsLeft: 29,
        ),
        NewPasswordState(matches: true),
      ],
      verify: (_) => expect(ticker.started, [30]),
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'does not save while the wait is on',
      build: build,
      seed: () => const NewPasswordState(
        status: NewPasswordStatus.waiting,
        matches: true,
        waitSecondsLeft: 12,
      ),
      act: (bloc) => bloc.add(const NewPasswordSubmitted('abcdefg1')),
      expect: () => const <NewPasswordState>[],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'typing during a wait keeps the wait',
      build: build,
      seed: () => const NewPasswordState(
        status: NewPasswordStatus.waiting,
        matches: true,
        waitSecondsLeft: 12,
      ),
      act: (bloc) => bloc.add(typed('abc', 'ab')),
      expect: () => const [
        NewPasswordState(
          status: NewPasswordStatus.waiting,
          mismatch: true,
          waitSecondsLeft: 12,
        ),
      ],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'reports a busy server',
      setUp: () => demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.unavailable),
      ),
      build: build,
      act: typeAndSave,
      skip: 2,
      expect: () => const [
        NewPasswordState(status: NewPasswordStatus.unavailable, matches: true),
      ],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'reports no connection while saving',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: typeAndSave,
      skip: 2,
      expect: () => [
        isA<NewPasswordState>().having(
          (state) => state.status,
          'status',
          NewPasswordStatus.noConnection,
        ),
      ],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: typeAndSave,
      skip: 2,
      expect: () => [
        isA<NewPasswordState>().having(
          (state) => state.status,
          'status',
          NewPasswordStatus.failure,
        ),
      ],
      errors: () => [isA<ServerException>()],
    );
  });
}
