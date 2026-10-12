import 'package:bloc_test/bloc_test.dart';
import 'package:money_scribe/features/auth/bloc/app_lock_setting_bloc.dart';

import '../../../support/instant_app_lock_repository.dart';

void main() {
  blocTest<AppLockSettingBloc, AppLockSettingState>(
    'the lock is off before a PIN is saved',
    build: () => AppLockSettingBloc(repository: InstantAppLockRepository()),
    act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
    expect: () => [const AppLockSettingState()],
  );

  blocTest<AppLockSettingBloc, AppLockSettingState>(
    'the lock is on once a PIN is saved',
    build: () =>
        AppLockSettingBloc(repository: InstantAppLockRepository(pin: '1234')),
    act: (bloc) => bloc.add(const AppLockSettingRefreshed()),
    expect: () => [const AppLockSettingState(isEnabled: true)],
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
}
