part of 'code_verification_bloc.dart';

sealed class CodeVerificationEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: carry on counting the wait before a new code can be
/// asked for, if the server asked for one.
final class CodeVerificationStarted extends CodeVerificationEvent {
  const new();
}

/// The user changed the digits.
final class CodeEdited extends CodeVerificationEvent {
  const new();
}

/// The user typed the last digit or pressed the button.
final class CodeSubmitted extends CodeVerificationEvent {
  const new(this.code);

  final String code;

  @override
  List<Object> get props => [code];
}

/// The user asked for a new code. Changing the email needs the current
/// [password] again; the other purposes send none.
final class CodeResendRequested extends CodeVerificationEvent {
  const new({this.password});

  final String? password;

  @override
  List<Object> get props => [?password];
}

/// A second of the wait for a new code passed.
final class _CodeResendTicked extends CodeVerificationEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}

/// A second of the wait before the code can be checked again passed.
final class _CodeWaitTicked extends CodeVerificationEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
