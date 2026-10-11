part of 'pin_bloc.dart';

sealed class PinEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The user pressed a digit key.
final class PinDigitPressed extends PinEvent {
  const new(this.digit);

  final int digit;

  @override
  List<Object> get props => [digit];
}

/// The user pressed the backspace key.
final class PinBackspacePressed extends PinEvent {
  const new();
}

/// The user pressed "Forgot PIN?": sign out and sign in again.
final class ForgotPinPressed extends PinEvent {
  const new();
}
