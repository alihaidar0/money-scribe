part of 'change_password_bloc.dart';

sealed class ChangePasswordEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The user changed one of the three password fields.
final class ChangePasswordEdited extends ChangePasswordEvent {
  const new({
    required this.current,
    required this.next,
    required this.confirmation,
  });

  final String current;
  final String next;
  final String confirmation;

  @override
  List<Object> get props => [current, next, confirmation];
}

/// The user pressed Save password.
final class ChangePasswordSubmitted extends ChangePasswordEvent {
  const new();
}

/// A second of the wait before the password can be sent again passed.
final class _ChangePasswordWaitTicked extends ChangePasswordEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
