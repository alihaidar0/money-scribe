part of 'register_bloc.dart';

enum RegisterStatus {
  /// Waiting for the form.
  idle,

  /// The account is being created.
  submitting,

  /// A code was sent: the Verify your email screen follows. The answer is the
  /// same whether the address is new, pending or already registered.
  success,

  /// Something in the form was refused: see [RegisterState].
  rejected,

  /// The server asked to wait before the account is sent again: see
  /// [RegisterState.waitSecondsLeft].
  waiting,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class RegisterState extends Equatable {
  const new({
    this.status = RegisterStatus.idle,
    this.passwordProblem,
    this.passwordsDoNotMatch = false,
    this.emailInvalid = false,
    this.nameInvalid = false,
    this.waitSecondsLeft = 0,
  });

  final RegisterStatus status;

  /// What the server found wrong with the password, while [status] is
  /// `rejected`.
  final PasswordProblem? passwordProblem;

  /// The two password fields differ.
  final bool passwordsDoNotMatch;

  /// The server did not accept the email address.
  final bool emailInvalid;

  /// The server did not accept the name.
  final bool nameInvalid;

  /// Seconds until the account can be sent again, while [status] is `waiting`.
  final int waitSecondsLeft;

  @override
  List<Object?> get props => [
    status,
    passwordProblem,
    passwordsDoNotMatch,
    emailInvalid,
    nameInvalid,
    waitSecondsLeft,
  ];
}
