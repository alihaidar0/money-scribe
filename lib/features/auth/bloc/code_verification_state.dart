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

  /// The code is no longer valid; a new one must be sent.
  expired,

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
    this.attemptsLeft = 0,
  });

  final CodeVerificationStatus status;

  /// The address the code was sent to.
  final String email;

  /// Seconds until a new code can be asked for; `0` when it can.
  final int resendSecondsLeft;

  /// Tries left, while [status] is `wrong`.
  final int attemptsLeft;

  CodeVerificationState copyWith({
    CodeVerificationStatus? status,
    int? resendSecondsLeft,
    int? attemptsLeft,
  }) {
    return CodeVerificationState(
      email: email,
      status: status ?? this.status,
      resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
    );
  }

  @override
  List<Object> get props => [status, email, resendSecondsLeft, attemptsLeft];
}
