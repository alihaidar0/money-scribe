part of 'new_password_bloc.dart';

enum NewPasswordStatus {
  /// Waiting for a password typed twice.
  editing,

  /// The password is being saved.
  saving,

  /// The password was saved. The server ended every session of the account, so
  /// the person signs in again.
  saved,

  /// The server refused the password: see [NewPasswordState.passwordProblem].
  /// The reset is still open and another password may be tried.
  rejected,

  /// The reset ran out or was lost: a new code has to be asked for.
  expired,

  /// The server asked to wait before the password is sent again: see
  /// [NewPasswordState.waitSecondsLeft].
  waiting,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class NewPasswordState extends Equatable {
  const new({
    this.status = NewPasswordStatus.editing,
    this.matches = false,
    this.mismatch = false,
    this.passwordProblem,
    this.waitSecondsLeft = 0,
  });

  final NewPasswordStatus status;

  /// A password is typed and the confirmation is the same text.
  final bool matches;

  /// The confirmation differs from the password. Nothing typed in the
  /// confirmation yet is not a mismatch.
  final bool mismatch;

  /// What the server found wrong with the password, while [status] is
  /// `rejected`.
  final PasswordProblem? passwordProblem;

  /// Seconds until the password can be sent again, while [status] is
  /// `waiting`.
  final int waitSecondsLeft;

  /// Whether the password can be saved.
  bool get isValid => matches;

  NewPasswordState copyWith({
    NewPasswordStatus? status,
    PasswordProblem? passwordProblem,
    int? waitSecondsLeft,
  }) {
    return NewPasswordState(
      status: status ?? this.status,
      matches: matches,
      mismatch: mismatch,
      // A refusal belongs to the attempt that got it.
      passwordProblem: passwordProblem,
      waitSecondsLeft: waitSecondsLeft ?? this.waitSecondsLeft,
    );
  }

  @override
  List<Object?> get props => [
    status,
    matches,
    mismatch,
    passwordProblem,
    waitSecondsLeft,
  ];
}
