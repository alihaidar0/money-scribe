part of 'change_email_bloc.dart';

sealed class ChangeEmailEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The user changed one of the two fields.
final class ChangeEmailEdited extends ChangeEmailEvent {
  const new({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// The user pressed Send code.
final class ChangeEmailSubmitted extends ChangeEmailEvent {
  const new();
}

/// A second of the wait before the request can be sent again passed.
final class _ChangeEmailWaitTicked extends ChangeEmailEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
