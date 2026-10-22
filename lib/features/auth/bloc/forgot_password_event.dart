part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const new();
}

/// The user pressed Send code.
final class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  const new(this.email);

  final String email;

  @override
  List<Object> get props => [email];
}

/// A second of the wait before a code can be asked for again passed.
final class _ForgotPasswordWaitTicked extends ForgotPasswordEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
