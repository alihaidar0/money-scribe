part of 'sign_in_bloc.dart';

enum SignInStatus {
  /// Waiting for the email and password.
  idle,

  /// The credentials are being checked.
  submitting,

  /// The person is signed in.
  success,

  /// No account has this email address: said under the email field.
  emailNotRegistered,

  /// The account exists but the password is wrong: said under the password
  /// field.
  wrongPassword,

  /// The server wants a bot challenge to be solved before it checks the email
  /// and password: the challenge opens, and its token goes with the next send.
  challengeRequired,

  /// The token of the challenge was refused (wrong, expired or used): a new
  /// challenge opens.
  challengeRejected,

  /// The server refused the sign-in without naming a field (a deactivated
  /// account, for instance): said in a banner.
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
