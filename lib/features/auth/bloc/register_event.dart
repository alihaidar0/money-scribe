part of 'register_bloc.dart';

sealed class RegisterEvent extends Equatable {
  const new();
}

/// The user pressed Create account.
final class RegisterSubmitted extends RegisterEvent {
  const new({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmation,
  });

  final String name;
  final String email;

  /// The password as typed: never trimmed or changed.
  final String password;

  /// The second password field, which must be the same text.
  final String confirmation;

  @override
  List<Object> get props => [name, email, password, confirmation];
}

/// A second of the wait before the account can be sent again passed.
final class _RegisterWaitTicked extends RegisterEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
