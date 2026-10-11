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
  });

  /// The digits typed so far.
  final String pin;

  final PinStatus status;
  final PinStage stage;

  /// Whether keys are ignored: a PIN is being checked, or the screen is done.
  bool get isBusy =>
      status == PinStatus.checking ||
      status == PinStatus.accepted ||
      status == PinStatus.signedOut;

  PinState copyWith({String? pin, PinStatus? status}) {
    return PinState(
      pin: pin ?? this.pin,
      status: status ?? this.status,
      stage: stage,
    );
  }

  @override
  List<Object> get props => [pin, status, stage];
}
