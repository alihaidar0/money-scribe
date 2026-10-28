part of 'revoke_others_bloc.dart';

enum RevokeOthersStatus {
  /// The person is typing the password.
  editing,

  /// The password is being checked and the devices signed out.
  revoking,

  /// The other devices were signed out.
  done,

  /// The password is not the password of the account.
  wrongPassword,

  /// Too many wrong passwords: the button waits, see
  /// [RevokeOthersState.waitSecondsLeft].
  waiting,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class RevokeOthersState extends Equatable {
  const new({
    this.status = RevokeOthersStatus.editing,
    this.password = '',
    this.waitSecondsLeft = 0,
    this.result,
  });

  final RevokeOthersStatus status;
  final String password;

  /// Seconds until the password can be sent again, while [status] is
  /// `waiting`.
  final int waitSecondsLeft;

  /// What was done, once [status] is `done`.
  final OthersSignedOut? result;

  RevokeOthersState copyWith({
    RevokeOthersStatus? status,
    int? waitSecondsLeft,
    OthersSignedOut? result,
  }) {
    return RevokeOthersState(
      status: status ?? this.status,
      password: password,
      waitSecondsLeft: waitSecondsLeft ?? this.waitSecondsLeft,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [status, password, waitSecondsLeft, result];
}
