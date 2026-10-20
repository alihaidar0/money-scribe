import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/bloc/forgot_password_bloc.dart';
import 'package:money_scribe/features/auth/bloc/new_password_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';

void main() {
  late DemoController demo;
  late FakeAuthRepository auth;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    auth = FakeAuthRepository(demo: demo);
  });

  group('ForgotPasswordBloc', () {
    ForgotPasswordBloc build() => ForgotPasswordBloc(repository: auth);

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
    NewPasswordBloc build() => NewPasswordBloc(repository: auth);

    NewPasswordChanged typed(String password, [String? confirmation]) {
      return NewPasswordChanged(
        password: password,
        confirmation: confirmation ?? password,
      );
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
      'saves a password typed twice',
      build: build,
      act: (bloc) async {
        bloc.add(typed('abcdefg1'));
        await pumpEventQueue();
        bloc.add(const NewPasswordSubmitted('abcdefg1'));
      },
      skip: 1,
      expect: () => const [
        NewPasswordState(status: NewPasswordStatus.saving, matches: true),
        NewPasswordState(status: NewPasswordStatus.saved, matches: true),
      ],
    );

    blocTest<NewPasswordBloc, NewPasswordState>(
      'reports no connection while saving',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(typed('abcdefg1'));
        await pumpEventQueue();
        bloc.add(const NewPasswordSubmitted('abcdefg1'));
      },
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
      act: (bloc) async {
        bloc.add(typed('abcdefg1'));
        await pumpEventQueue();
        bloc.add(const NewPasswordSubmitted('abcdefg1'));
      },
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
