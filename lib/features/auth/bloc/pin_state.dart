part of 'pin_bloc.dart';

enum PinStatus {
  /// Waiting for digits.
  entering,

  /// A complete PIN is being checked or saved.
  checking,

  /// The PIN opened the app, or was saved.
  accepted,

  /// The PIN is not the saved one.
  wrong,

  /// Wrong PINs started a pause: nothing is checked until
  /// [PinState.pauseSecondsLeft] reaches zero.
  paused,

  /// Too many wrong PINs in a row: the person was signed out and opens the
  /// app with the account password.
  tooManyFailures,

  /// The repeated PIN differs from the first one.
  mismatch,

  /// The person was signed out ("Forgot PIN?").
  signedOut,
}

/// Which of the two entries of a new PIN is being typed.
enum PinStage { enter, repeat }

final class PinState extends Equatable {
  const new({
    this.pin = '',
    this.status = PinStatus.entering,
    this.stage = PinStage.enter,
    this.pauseSecondsLeft = 0,
  });

  /// The digits typed so far.
  final String pin;

  final PinStatus status;
  final PinStage stage;

  /// Seconds until a PIN is checked again, while [status] is `paused`.
  final int pauseSecondsLeft;

  /// Whether keys are ignored: a PIN is being checked, or the screen is done.
  bool get isBusy =>
      status == PinStatus.checking ||
      status == PinStatus.accepted ||
      status == PinStatus.signedOut ||
      status == PinStatus.paused ||
      status == PinStatus.tooManyFailures;

  PinState copyWith({String? pin, PinStatus? status, int? pauseSecondsLeft}) {
    return PinState(
      pin: pin ?? this.pin,
      status: status ?? this.status,
      stage: stage,
      pauseSecondsLeft: pauseSecondsLeft ?? this.pauseSecondsLeft,
    );
  }

  @override
  List<Object> get props => [pin, status, stage, pauseSecondsLeft];
}
