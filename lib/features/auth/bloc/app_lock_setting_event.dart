part of 'app_lock_setting_bloc.dart';

sealed class AppLockSettingEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The row appeared, or the person came back from creating a PIN: ask whether
/// the app lock is on.
final class AppLockSettingRefreshed extends AppLockSettingEvent {
  const new();
}

/// The user turned the switch off.
final class AppLockTurnedOff extends AppLockSettingEvent {
  const new();
}

/// The user chose how long the app may stay in the background before it
/// locks.
final class AppLockTimeoutChosen extends AppLockSettingEvent {
  const new(this.timeout);

  final LockTimeout timeout;

  @override
  List<Object> get props => [timeout];
}
