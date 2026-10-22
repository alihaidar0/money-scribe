part of 'sign_in_bloc.dart';

sealed class SignInEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The Sign in screen opened: carry on counting if sign-in is still locked.
final class SignInStarted extends SignInEvent {
  const new();
}

/// The user pressed Sign in.
final class SignInSubmitted extends SignInEvent {
  const new({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// The person changed the email address: a refusal of the old one no longer
/// applies.
final class SignInEmailEdited extends SignInEvent {
  const new();
}

/// The person changed the password: a refusal of the old one no longer applies.
final class SignInPasswordEdited extends SignInEvent {
  const new();
}

/// A second of the lock passed.
final class _SignInLockTicked extends SignInEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
