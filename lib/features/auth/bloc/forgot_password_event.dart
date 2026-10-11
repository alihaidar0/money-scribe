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
