import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_setting_bloc.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';

import '../../../support/instant_app_lock_repository.dart';

void main() {
  blocTest<AppLockSettingBloc, AppLockSettingState>(
    'the lock is off before a PIN is saved',
    build: () => AppLockSettingBloc(repository: InstantAppLockRepository()),
    act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
    expect: () => [const AppLockSettingState()],
  );

  blocTest<AppLockSettingBloc, AppLockSettingState>(
    'the lock is on once a PIN is saved, with the timeout that was chosen',
    build: () => AppLockSettingBloc(
      repository: InstantAppLockRepository(pin: '1234')
        ..currentTimeout = LockTimeout.fiveMinutes,
    ),
    act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
    expect: () => [
      const AppLockSettingState(
        isEnabled: true,
        timeout: LockTimeout.fiveMinutes,
      ),
    ],
  );

  blocTest<AppLockSettingBloc, AppLockSettingState>(
    'turning the lock off forgets the PIN',
    build: () =>
        AppLockSettingBloc(repository: InstantAppLockRepository(pin: '1234')),
    act: (bloc) => bloc.add(const AppLockTurnedOff()),
    expect: () => [
      const AppLockSettingState(isEnabled: true, isBusy: true),
      const AppLockSettingState(),
    ],
  );

  test('a new lock starts with one minute', () {
    expect(LockTimeout.standard, LockTimeout.oneMinute);
  });

  blocTest<AppLockSettingBloc, AppLockSettingState>(
    'a chosen timeout is saved and shown',
    build: () {
      final repository = InstantAppLockRepository(pin: '1234');
      addTearDown(
        () => expect(repository.currentTimeout, LockTimeout.immediately),
      );
      return AppLockSettingBloc(repository: repository);
    },
    seed: () => const AppLockSettingState(isEnabled: true),
    act: (bloc) =>
        bloc.add(const AppLockTimeoutChosen(LockTimeout.immediately)),
    expect: () => [
      const AppLockSettingState(
        isEnabled: true,
        timeout: LockTimeout.immediately,
      ),
    ],
  );
}
