part of 'change_password_bloc.dart';

enum ChangePasswordStatus {
  /// The person is typing.
  editing,

  /// The new password is being saved.
  saving,

  /// The new password was saved.
  saved,

  /// The current password is not the password.
  wrongCurrent,

  /// The server refused the new password: see
  /// [ChangePasswordState.passwordProblem].
  rejected,

  /// The server asked to wait before the password is sent again: see
  /// [ChangePasswordState.waitSecondsLeft].
  waiting,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class ChangePasswordState extends Equatable {
  const new({
    this.status = ChangePasswordStatus.editing,
    this.current = '',
    this.next = '',
    this.confirmation = '',
    this.passwordProblem,
    this.waitSecondsLeft = 0,
  });

  final ChangePasswordStatus status;
  final String current;
  final String next;
  final String confirmation;

  /// What the server found wrong with the new password, while [status] is
  /// `rejected`.
  final PasswordProblem? passwordProblem;

  /// Seconds until the password can be sent again, while [status] is
  /// `waiting`.
  final int waitSecondsLeft;

  /// Whether the confirmation differs from the new password. Nothing typed in
  /// the confirmation yet is not a mismatch.
  bool get mismatch => confirmation.isNotEmpty && confirmation != next;

  /// Whether the form can be saved: the current password and a new one are
  /// typed, and the confirmation is the same text.
  bool get isValid =>
      current.isNotEmpty && next.isNotEmpty && confirmation == next;

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    PasswordProblem? passwordProblem,
    int? waitSecondsLeft,
  }) {
    return ChangePasswordState(
      status: status ?? this.status,
      current: current,
      next: next,
      confirmation: confirmation,
      // A refusal belongs to the attempt that got it.
      passwordProblem: passwordProblem,
      waitSecondsLeft: waitSecondsLeft ?? this.waitSecondsLeft,
    );
  }

  @override
  List<Object?> get props => [
    status,
    current,
    next,
    confirmation,
    passwordProblem,
    waitSecondsLeft,
  ];
}
