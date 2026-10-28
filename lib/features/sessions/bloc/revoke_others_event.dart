part of 'revoke_others_bloc.dart';

sealed class RevokeOthersEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The user typed the password.
final class RevokeOthersPasswordEdited extends RevokeOthersEvent {
  const new(this.password);

  final String password;

  @override
  List<Object?> get props => [password];
}

/// The user pressed "Sign out others".
final class RevokeOthersSubmitted extends RevokeOthersEvent {
  const new();
}

/// A second of the wait the server asked for went by.
final class _RevokeOthersWaitTicked extends RevokeOthersEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object?> get props => [secondsLeft];
}
