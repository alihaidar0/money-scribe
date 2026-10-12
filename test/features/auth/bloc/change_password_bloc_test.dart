import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/change_password_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';

void main() {
  late DemoController demo;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
  });

  ChangePasswordBloc build() {
    return ChangePasswordBloc(
      repository: FakeAuthRepository(demo: demo, signedIn: true),
    );
  }

  const valid = ChangePasswordEdited(
    current: 'old-password',
    next: 'new-password-1',
    confirmation: 'new-password-1',
  );

  test('starts empty and cannot be saved', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.isValid, isFalse);
    expect(bloc.state.mismatch, isFalse);
  });

  group('the rules', () {
    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'a short new password cannot be saved',
      build: build,
      act: (bloc) => bloc.add(
        const ChangePasswordEdited(
          current: 'old',
          next: 'short',
          confirmation: 'short',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.hasMinLength, isFalse);
        expect(bloc.state.isValid, isFalse);
      },
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'a confirmation that differs is a mismatch',
      build: build,
      act: (bloc) => bloc.add(
        const ChangePasswordEdited(
          current: 'old',
          next: 'new-password-1',
          confirmation: 'new-password-2',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.mismatch, isTrue);
        expect(bloc.state.isValid, isFalse);
      },
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'an empty current password cannot be saved',
      build: build,
      act: (bloc) => bloc.add(
        const ChangePasswordEdited(
          current: '',
          next: 'new-password-1',
          confirmation: 'new-password-1',
        ),
      ),
      verify: (bloc) => expect(bloc.state.isValid, isFalse),
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'everything right can be saved',
      build: build,
      act: (bloc) => bloc.add(valid),
      verify: (bloc) => expect(bloc.state.isValid, isTrue),
    );
  });

  group('ChangePasswordSubmitted', () {
    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'saves the new password',
      build: build,
      act: (bloc) => bloc
        ..add(valid)
        ..add(const ChangePasswordSubmitted()),
      verify: (bloc) => expect(bloc.state.status, ChangePasswordStatus.saved),
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'does nothing while the form is not valid',
      build: build,
      act: (bloc) => bloc.add(const ChangePasswordSubmitted()),
      expect: () => <ChangePasswordState>[],
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'a wrong current password is told, and typing starts a new try',
      setUp: () =>
          demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword)),
      build: build,
      act: (bloc) async {
        bloc.add(valid);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ChangePasswordSubmitted());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, ChangePasswordStatus.wrongCurrent);
        bloc.add(valid);
      },
      verify: (bloc) => expect(bloc.state.status, ChangePasswordStatus.editing),
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(valid);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ChangePasswordSubmitted());
      },
      verify: (bloc) =>
          expect(bloc.state.status, ChangePasswordStatus.noConnection),
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) async {
        bloc.add(valid);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ChangePasswordSubmitted());
      },
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, ChangePasswordStatus.failure),
    );
  });
}
