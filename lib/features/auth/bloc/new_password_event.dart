part of 'new_password_bloc.dart';

sealed class NewPasswordEvent extends Equatable {
  const new();
}

/// The user changed one of the two password fields.
final class NewPasswordChanged extends NewPasswordEvent {
  const new({required this.password, required this.confirmation});

  final String password;
  final String confirmation;

  @override
  List<Object> get props => [password, confirmation];
}

/// The user pressed Save password.
final class NewPasswordSubmitted extends NewPasswordEvent {
  const new(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}
