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

  /// The password is right but the email address is not verified yet: the
  /// Verify your email screen follows.
  emailNotVerified,

  /// The server asked to wait (too many wrong attempts, or too many
  /// requests): sign-in is locked until the countdown ends.
  locked,

  /// The server is busy: try again shortly.
  unavailable,

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
