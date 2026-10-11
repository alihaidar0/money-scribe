part of 'code_verification_bloc.dart';

sealed class CodeVerificationEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: start the wait before a new code can be asked for.
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

/// The user asked for a new code.
final class CodeResendRequested extends CodeVerificationEvent {
  const new();
}

/// A second of the wait for a new code passed.
final class _CodeResendTicked extends CodeVerificationEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object> get props => [secondsLeft];
}
