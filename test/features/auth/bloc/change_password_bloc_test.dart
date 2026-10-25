import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/bloc/change_password_bloc.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

import '../../../support/fake_ticker.dart';

/// A phone that cannot be asked whether the fingerprint sign-in is on.
class _UnreadableKeys extends FakeDeviceKeyRepository {
  new({required super.demo, required super.auth});

  @override
  Future<bool> isEnabled() {
    throw StateError('The secure storage cannot be read');
  }
}

void main() {
  late DemoController demo;
  late FakeTicker ticker;
  late FakeAuthRepository auth;
  late FakeDeviceKeyRepository keys;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    ticker = FakeTicker();
    auth = FakeAuthRepository(demo: demo, signedIn: true);
    keys = FakeDeviceKeyRepository(demo: demo, auth: auth);
  });

  ChangePasswordBloc build() {
    return ChangePasswordBloc(
      repository: auth,
      deviceKeys: keys,
      ticker: ticker,
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
      'the app applies no length rule: only the server does',
      build: build,
      act: (bloc) => bloc.add(
        const ChangePasswordEdited(
          current: 'old',
          next: 'x',
          confirmation: 'x',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.mismatch, isFalse);
        expect(bloc.state.isValid, isTrue);
      },
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'an empty new password cannot be saved',
      build: build,
      act: (bloc) => bloc.add(
        const ChangePasswordEdited(current: 'old', next: '', confirmation: ''),
      ),
      verify: (bloc) => expect(bloc.state.isValid, isFalse),
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'spaces are part of the password: it is never trimmed',
      build: build,
      act: (bloc) => bloc.add(
        const ChangePasswordEdited(
          current: 'old',
          next: ' a b ',
          confirmation: 'a b',
        ),
      ),
      verify: (bloc) => expect(bloc.state.mismatch, isTrue),
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

  group('what the server says', () {
    Future<void> submit(ChangePasswordBloc bloc) async {
      bloc.add(valid);
      await pumpEventQueue();
      bloc.add(const ChangePasswordSubmitted());
      await pumpEventQueue();
    }

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'a refused new password is worded from the reason, and typing again '
      'clears it',
      setUp: () => demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.passwordRefused),
      ),
      build: build,
      act: (bloc) async {
        await submit(bloc);
        expect(bloc.state.status, ChangePasswordStatus.rejected);
        expect(
          bloc.state.passwordProblem,
          const PasswordProblem(
            PasswordIssue.tooShort,
            limit: FakeAuthRepository.demoMinimumPasswordLength,
          ),
        );
        bloc.add(valid);
      },
      verify: (bloc) {
        expect(bloc.state.status, ChangePasswordStatus.editing);
        expect(bloc.state.passwordProblem, isNull);
      },
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'the same password as the current one is refused',
      build: build,
      act: (bloc) async {
        bloc.add(
          const ChangePasswordEdited(
            current: 'same-password',
            next: 'same-password',
            confirmation: 'same-password',
          ),
        );
        await pumpEventQueue();
        bloc.add(const ChangePasswordSubmitted());
      },
      verify: (bloc) {
        expect(bloc.state.status, ChangePasswordStatus.rejected);
        expect(
          bloc.state.passwordProblem,
          const PasswordProblem(PasswordIssue.unchanged),
        );
      },
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'a lock after wrong passwords is a wait the server gave, counted down',
      setUp: () => demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      ),
      build: build,
      act: (bloc) async {
        await submit(bloc);
        ticker.tick(899);
        await pumpEventQueue();
        ticker.tick(0);
      },
      skip: 2,
      expect: () => [
        isA<ChangePasswordState>()
            .having((s) => s.status, 'status', ChangePasswordStatus.waiting)
            .having((s) => s.waitSecondsLeft, 'left', 900),
        isA<ChangePasswordState>()
            .having((s) => s.status, 'status', ChangePasswordStatus.waiting)
            .having((s) => s.waitSecondsLeft, 'left', 899),
        isA<ChangePasswordState>()
            .having((s) => s.status, 'status', ChangePasswordStatus.editing)
            .having((s) => s.waitSecondsLeft, 'left', 0),
      ],
      verify: (_) => expect(ticker.started, [900]),
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'typing during the wait keeps the wait, and nothing is sent',
      setUp: () => demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      ),
      build: build,
      act: (bloc) async {
        await submit(bloc);
        bloc
          ..add(valid)
          ..add(const ChangePasswordSubmitted());
        await pumpEventQueue();
      },
      verify: (bloc) {
        expect(bloc.state.status, ChangePasswordStatus.waiting);
        expect(bloc.state.waitSecondsLeft, 900);
        expect(ticker.started, [900]);
      },
    );

    blocTest<ChangePasswordBloc, ChangePasswordState>(
      'reports a busy server',
      setUp: () => demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
      ),
      build: build,
      act: submit,
      verify: (bloc) =>
          expect(bloc.state.status, ChangePasswordStatus.unavailable),
    );
  });

  group('the fingerprint sign-in', () {
    Future<ChangePasswordBloc> saveWith(ChangePasswordBloc bloc) async {
      addTearDown(bloc.close);
      bloc
        ..add(valid)
        ..add(const ChangePasswordSubmitted());
      await bloc.stream.firstWhere(
        (s) =>
            s.status != ChangePasswordStatus.editing &&
            s.status != ChangePasswordStatus.saving,
      );
      return bloc;
    }

    test(
      'is offered again when it was on, as the server removed its key',
      () async {
        await keys.enable(password: 'old-password', prompt: 'Confirm');

        final bloc = await saveWith(build());

        expect(bloc.state.status, ChangePasswordStatus.saved);
        expect(bloc.state.offerFingerprint, isTrue);
        expect(await keys.isEnabled(), isFalse);
        // The new password is what turns it on again.
        expect(bloc.state.next, 'new-password-1');
      },
    );

    test('is not offered when it was off', () async {
      final bloc = await saveWith(build());

      expect(bloc.state.status, ChangePasswordStatus.saved);
      expect(bloc.state.offerFingerprint, isFalse);
    });

    test('is not offered when the password was not changed', () async {
      await keys.enable(password: 'old-password', prompt: 'Confirm');
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.passwordRefused),
      );

      final bloc = await saveWith(build());

      expect(bloc.state.status, ChangePasswordStatus.rejected);
      expect(bloc.state.offerFingerprint, isFalse);
      // Nothing was removed, so it is still on.
      expect(await keys.isEnabled(), isTrue);
    });

    test('is not offered by a phone that cannot be asked', () async {
      final unreadable = _UnreadableKeys(demo: demo, auth: auth);
      final bloc = await saveWith(
        ChangePasswordBloc(
          repository: auth,
          deviceKeys: unreadable,
          ticker: ticker,
        ),
      );

      // The password is saved all the same.
      expect(bloc.state.status, ChangePasswordStatus.saved);
      expect(bloc.state.offerFingerprint, isFalse);
    });

    test('typing again after saving forgets the offer', () async {
      await keys.enable(password: 'old-password', prompt: 'Confirm');
      final bloc = await saveWith(build());
      expect(bloc.state.offerFingerprint, isTrue);

      bloc.add(valid);
      await pumpEventQueue();

      expect(bloc.state.offerFingerprint, isFalse);
    });
  });
}
