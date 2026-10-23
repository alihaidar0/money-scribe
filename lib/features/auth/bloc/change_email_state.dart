part of 'change_email_bloc.dart';

enum ChangeEmailStatus {
  /// The person is typing.
  editing,

  /// The request is being sent.
  sending,

  /// The server sent a code to the new address: the code screen follows.
  sent,

  /// The current password is wrong.
  wrongPassword,

  /// The server refused the new address: see [ChangeEmailState.issue].
  rejected,

  /// The server asked to wait before the request is sent again: see
  /// [ChangeEmailState.waitSecondsLeft].
  waiting,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class ChangeEmailState extends Equatable {
  const new({
    this.status = ChangeEmailStatus.editing,
    this.email = '',
    this.password = '',
    this.issue,
    this.waitSecondsLeft = 0,
  });

  final ChangeEmailStatus status;

  /// The new address as typed, never changed here.
  final String email;

  /// The current password as typed, never trimmed.
  final String password;

  /// Why the server refused the address, while [status] is `rejected`.
  final EmailIssue? issue;

  /// Seconds until the request can be sent again, while [status] is
  /// `waiting`.
  final int waitSecondsLeft;

  /// Whether the request can be sent: an address and the password are typed.
  bool get canSend => email.trim().isNotEmpty && password.isNotEmpty;

  ChangeEmailState copyWith({
    ChangeEmailStatus? status,
    EmailIssue? issue,
    int? waitSecondsLeft,
  }) {
    return ChangeEmailState(
      status: status ?? this.status,
      email: email,
      password: password,
      // A refusal belongs to the attempt that got it.
      issue: issue,
      waitSecondsLeft: waitSecondsLeft ?? this.waitSecondsLeft,
    );
  }

  @override
  List<Object?> get props => [status, email, password, issue, waitSecondsLeft];
}
