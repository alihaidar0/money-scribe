part of 'app_lock_bloc.dart';

enum AppLockStatus {
  /// Waiting for the fingerprint, or for the PIN.
  locked,

  /// The sensor is being read.
  checking,

  /// The fingerprint matched, and the app is unlocked.
  unlocked,

  /// The fingerprint did not match, or could not be read.
  notRecognised,
}

final class AppLockState extends Equatable {
  const new({
    this.status = AppLockStatus.locked,
    this.canUseBiometrics = false,
  });

  final AppLockStatus status;

  /// Whether the device has a fingerprint (or face) the person enrolled. The
  /// button is only shown when it does.
  final bool canUseBiometrics;

  AppLockState copyWith({AppLockStatus? status}) {
    return AppLockState(
      status: status ?? this.status,
      canUseBiometrics: canUseBiometrics,
    );
  }

  @override
  List<Object> get props => [status, canUseBiometrics];
}
