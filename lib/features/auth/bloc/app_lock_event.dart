part of 'app_lock_bloc.dart';

sealed class AppLockEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The user touched the fingerprint button.
final class BiometricUnlockRequested extends AppLockEvent {
  const new();
}
