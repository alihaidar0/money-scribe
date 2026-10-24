import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_setting_bloc.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';

import '../../../support/instant_app_lock_repository.dart';

void main() {
  AppLockSettingBloc build(InstantAppLockRepository repository) {
    return AppLockSettingBloc(repository: repository);
  }

  group('what the rows show', () {
    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'the lock is off before a PIN is saved, and so is the fingerprint',
      build: () => build(InstantAppLockRepository()),
      act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
      expect: () => [const AppLockSettingState(biometricsAvailable: true)],
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'a saved PIN, the timeout and the fingerprint switch are read back',
      build: () => build(
        InstantAppLockRepository(pin: '1234')
          ..currentTimeout = LockTimeout.fiveMinutes,
      ),
      act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
      expect: () => [
        const AppLockSettingState(
          isEnabled: true,
          timeout: LockTimeout.fiveMinutes,
          biometricsAvailable: true,
          biometricsEnabled: true,
        ),
      ],
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'a fingerprint that was never turned on shows as off',
      build: () =>
          build(InstantAppLockRepository(pin: '1234', biometricsOn: false)),
      act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
      expect: () => [
        const AppLockSettingState(isEnabled: true, biometricsAvailable: true),
      ],
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'a device with no fingerprint says so',
      build: () => build(
        InstantAppLockRepository(
          pin: '1234',
          deviceHasFingerprint: false,
          biometricsOn: false,
        ),
      ),
      act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
      expect: () => [const AppLockSettingState(isEnabled: true)],
    );
  });

  group('turning the lock off', () {
    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'forgets the PIN and the fingerprint switch, not what the device has',
      build: () => build(InstantAppLockRepository(pin: '1234')),
      seed: () => const AppLockSettingState(
        isEnabled: true,
        biometricsAvailable: true,
        biometricsEnabled: true,
      ),
      act: (bloc) => bloc.add(const AppLockTurnedOff()),
      expect: () => [
        const AppLockSettingState(
          isEnabled: true,
          isBusy: true,
          biometricsAvailable: true,
          biometricsEnabled: true,
        ),
        const AppLockSettingState(biometricsAvailable: true),
      ],
    );
  });

  test('a new lock asks every time the app comes back', () {
    expect(LockTimeout.standard, LockTimeout.immediately);
  });

  blocTest<AppLockSettingBloc, AppLockSettingState>(
    'a chosen timeout is saved and shown',
    build: () {
      final repository = InstantAppLockRepository(pin: '1234');
      addTearDown(
        () => expect(repository.currentTimeout, LockTimeout.oneMinute),
      );
      return build(repository);
    },
    seed: () => const AppLockSettingState(isEnabled: true),
    act: (bloc) => bloc.add(const AppLockTimeoutChosen(LockTimeout.oneMinute)),
    expect: () => [
      const AppLockSettingState(
        isEnabled: true,
        timeout: LockTimeout.oneMinute,
      ),
    ],
  );

  group('the fingerprint switch', () {
    const on = BiometricsSwitched(turnOn: true, reason: 'Confirm');
    const off = BiometricsSwitched(turnOn: false, reason: 'Confirm');
    const seed = AppLockSettingState(
      isEnabled: true,
      biometricsAvailable: true,
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'turns on once the fingerprint matched',
      build: () =>
          build(InstantAppLockRepository(pin: '1234', biometricsOn: false)),
      seed: () => seed,
      act: (bloc) => bloc.add(on),
      expect: () => [
        const AppLockSettingState(
          isEnabled: true,
          isBusy: true,
          biometricsAvailable: true,
        ),
        const AppLockSettingState(
          isEnabled: true,
          biometricsAvailable: true,
          biometricsEnabled: true,
        ),
      ],
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'asks for the fingerprint with the reason it was given',
      build: () =>
          build(InstantAppLockRepository(pin: '1234', biometricsOn: false)),
      seed: () => seed,
      act: (bloc) => bloc.add(on),
      verify: (bloc) => expect(bloc.state.biometricsEnabled, isTrue),
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'stays off when the fingerprint did not match, and says so',
      build: () => build(
        InstantAppLockRepository(
          pin: '1234',
          biometricsOn: false,
          biometricsMatch: false,
        ),
      ),
      seed: () => seed,
      act: (bloc) => bloc.add(on),
      expect: () => [
        const AppLockSettingState(
          isEnabled: true,
          isBusy: true,
          biometricsAvailable: true,
        ),
        const AppLockSettingState(
          isEnabled: true,
          biometricsAvailable: true,
          biometricsRefused: true,
        ),
      ],
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'the PIN stays whatever the fingerprint does',
      build: () {
        final repository = InstantAppLockRepository(
          pin: '1234',
          biometricsOn: false,
          biometricsMatch: false,
        );
        addTearDown(() => expect(repository.pin, '1234'));
        return build(repository);
      },
      seed: () => seed,
      act: (bloc) => bloc.add(on),
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'turns off without asking for the fingerprint',
      build: () => build(InstantAppLockRepository(pin: '1234')),
      seed: () => const AppLockSettingState(
        isEnabled: true,
        biometricsAvailable: true,
        biometricsEnabled: true,
      ),
      act: (bloc) => bloc.add(off),
      verify: (bloc) {
        expect(bloc.state.biometricsEnabled, isFalse);
        expect(bloc.state.isEnabled, isTrue);
      },
    );
  });

  group('the fingerprint switch with no PIN lock yet', () {
    const on = BiometricsSwitched(turnOn: true, reason: 'Confirm');
    const seed = AppLockSettingState(biometricsAvailable: true);

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'confirms the fingerprint first, then asks for a PIN; nothing is on yet',
      build: () => build(InstantAppLockRepository(biometricsOn: false)),
      seed: () => seed,
      act: (bloc) => bloc.add(on),
      expect: () => [
        const AppLockSettingState(isBusy: true, biometricsAvailable: true),
        const AppLockSettingState(biometricsAvailable: true, pinNeeded: true),
      ],
      verify: (bloc) {
        expect(bloc.state.biometricsEnabled, isFalse);
        expect(bloc.state.isEnabled, isFalse);
      },
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'a fingerprint that does not match asks for no PIN',
      build: () => build(
        InstantAppLockRepository(biometricsOn: false, biometricsMatch: false),
      ),
      seed: () => seed,
      act: (bloc) => bloc.add(on),
      expect: () => [
        const AppLockSettingState(isBusy: true, biometricsAvailable: true),
        const AppLockSettingState(
          biometricsAvailable: true,
          biometricsRefused: true,
        ),
      ],
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'a saved PIN turns the confirmed fingerprint on with it',
      build: () => build(
        // The Create a PIN screen has saved the PIN by now.
        InstantAppLockRepository(pin: '1234', biometricsOn: false),
      ),
      seed: () => seed,
      act: (bloc) => bloc.add(const PinCreatedForFingerprint()),
      expect: () => [
        const AppLockSettingState(
          isEnabled: true,
          biometricsAvailable: true,
          biometricsEnabled: true,
        ),
      ],
    );

    blocTest<AppLockSettingBloc, AppLockSettingState>(
      'a Create a PIN screen that was left turns nothing on',
      build: () => build(InstantAppLockRepository(biometricsOn: false)),
      seed: () => seed,
      act: (bloc) => bloc.add(const PinCreatedForFingerprint()),
      verify: (bloc) {
        expect(bloc.state.isEnabled, isFalse);
        expect(bloc.state.biometricsEnabled, isFalse);
      },
    );
  });
}
