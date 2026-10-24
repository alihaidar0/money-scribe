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

/// The user turned the fingerprint switch on or off. Turning it on asks for
/// the fingerprint first, showing [reason], and keeps it off when it does not
/// match.
final class BiometricsSwitched extends AppLockSettingEvent {
  const new({required this.turnOn, required this.reason});

  final bool turnOn;
  final String reason;

  @override
  List<Object> get props => [turnOn, reason];
}

/// The person came back from the Create a PIN screen after turning the
/// fingerprint on without a PIN: the fingerprint is turned on if the PIN was
/// saved, and stays off if the screen was left.
final class PinCreatedForFingerprint extends AppLockSettingEvent {
  const new();
}
