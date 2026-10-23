part of 'account_bloc.dart';

sealed class AccountEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: load the name and the email.
final class AccountStarted extends AccountEvent {
  const new();
}

/// The user pressed Try again.
final class AccountRetried extends AccountEvent {
  const new();
}

/// The user confirmed the Sign out dialog.
final class SignOutConfirmed extends AccountEvent {
  const new();
}

/// The user typed their password in the Delete account dialog and confirmed.
final class DeleteAccountConfirmed extends AccountEvent {
  const new(this.password);

  final String password;

  @override
  List<Object> get props => [password];
}

/// The user opened the Delete account dialog again: forget the last answer.
final class DeleteAccountDialogOpened extends AccountEvent {
  const new();
}

/// A second of the wait before the password can be sent again passed.
final class _DeleteWaitTicked extends AccountEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
