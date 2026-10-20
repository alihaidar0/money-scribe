part of 'code_verification_bloc.dart';

enum CodeVerificationStatus {
  /// Waiting for the digits.
  entering,

  /// The code is being checked.
  verifying,

  /// The code was correct.
  verified,

  /// The code was wrong: see [CodeVerificationState.attemptsLeft].
  wrong,

  /// The code is no longer valid (or none was ever sent to this address); a
  /// new one must be asked for.
  expired,

  /// Too many wrong codes: the code is dead. A new one can be asked for once
  /// [CodeVerificationState.resendSecondsLeft] reaches zero.
  attemptsExceeded,

  /// The server asked to wait before the code is checked again: see
  /// [CodeVerificationState.waitSecondsLeft].
  rateLimited,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class CodeVerificationState extends Equatable {
  const new({
    required this.email,
    required this.resendSecondsLeft,
    this.status = CodeVerificationStatus.entering,
    this.attemptsLeft,
    this.waitSecondsLeft = 0,
  });

  /// Tells [copyWith] that `attemptsLeft` was not given, because `null` is a
  /// value too.
  static const _keep = Object();

  final CodeVerificationStatus status;

  /// The address the code was sent to.
  final String email;

  /// Seconds until a new code can be asked for; `0` when it can.
  final int resendSecondsLeft;

  /// Tries left, while [status] is `wrong`, when the server says how many.
  final int? attemptsLeft;

  /// Seconds until the code can be checked again, while [status] is
  /// `rateLimited`.
  final int waitSecondsLeft;

  CodeVerificationState copyWith({
    CodeVerificationStatus? status,
    int? resendSecondsLeft,
    Object? attemptsLeft = _keep,
    int? waitSecondsLeft,
  }) {
    return CodeVerificationState(
      email: email,
      status: status ?? this.status,
      resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
      attemptsLeft: identical(attemptsLeft, _keep)
          ? this.attemptsLeft
          : attemptsLeft as int?,
      waitSecondsLeft: waitSecondsLeft ?? this.waitSecondsLeft,
    );
  }

  @override
  List<Object?> get props => [
    status,
    email,
    resendSecondsLeft,
    attemptsLeft,
    waitSecondsLeft,
  ];
}
