part of 'forgot_password_bloc.dart';

enum ForgotPasswordStatus {
  /// Waiting for the email.
  idle,

  /// The code is being sent.
  submitting,

  /// The code was sent.
  success,

  /// The server does not offer this yet: there is nothing to try again.
  notAvailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class ForgotPasswordState extends Equatable {
  const new({this.status = ForgotPasswordStatus.idle});

  final ForgotPasswordStatus status;

  @override
  List<Object> get props => [status];
}
