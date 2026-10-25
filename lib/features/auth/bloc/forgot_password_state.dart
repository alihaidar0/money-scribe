part of 'forgot_password_bloc.dart';

enum ForgotPasswordStatus {
  /// Waiting for the email.
  idle,

  /// The code is being sent.
  submitting,

  /// The code was sent. The answer is the same whether the address has an
  /// account or not.
  success,

  /// The server asked to wait before a code is asked for again: see
  /// [ForgotPasswordState.waitSecondsLeft].
  waiting,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class ForgotPasswordState extends Equatable {
  const new({
    this.status = ForgotPasswordStatus.idle,
    this.waitSecondsLeft = 0,
  });

  final ForgotPasswordStatus status;

  /// Seconds until a code can be asked for again, while [status] is `waiting`.
  final int waitSecondsLeft;

  @override
  List<Object> get props => [status, waitSecondsLeft];
}
