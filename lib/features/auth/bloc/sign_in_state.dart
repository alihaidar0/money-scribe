part of 'sign_in_bloc.dart';

enum SignInStatus {
  /// Waiting for the email and password.
  idle,

  /// The credentials are being checked.
  submitting,

  /// The person is signed in.
  success,

  /// The email or the password is wrong.
  wrongCredentials,

  /// Too many wrong attempts: sign-in is locked until the countdown ends.
  locked,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class SignInState extends Equatable {
  const new({this.status = SignInStatus.idle, this.lockSecondsLeft = 0});

  final SignInStatus status;

  /// Seconds until sign-in unlocks, while [status] is `locked`.
  final int lockSecondsLeft;

  @override
  List<Object> get props => [status, lockSecondsLeft];
}
