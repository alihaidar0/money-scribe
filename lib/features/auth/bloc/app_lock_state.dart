part of 'app_lock_bloc.dart';

enum AppLockStatus {
  /// Waiting for the fingerprint.
  locked,

  /// The sensor is being read.
  checking,

  /// The fingerprint matched.
  unlocked,

  /// The fingerprint did not match, or could not be read.
  notRecognised,
}

final class AppLockState extends Equatable {
  const new({this.status = AppLockStatus.locked});

  final AppLockStatus status;

  @override
  List<Object> get props => [status];
}
