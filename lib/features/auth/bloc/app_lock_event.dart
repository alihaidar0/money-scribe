part of 'app_lock_bloc.dart';

sealed class AppLockEvent extends Equatable {
  const new();
}

/// The screen opened: find out whether the fingerprint can be used and, when
/// it can, ask for it. [reason] is what the system dialog says.
final class AppLockStarted extends AppLockEvent {
  const new({required this.reason});

  final String reason;

  @override
  List<Object> get props => [reason];
}

/// The user touched the fingerprint button.
final class BiometricUnlockRequested extends AppLockEvent {
  const new({required this.reason});

  final String reason;

  @override
  List<Object> get props => [reason];
}
