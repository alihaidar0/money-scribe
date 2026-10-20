part of 'new_password_bloc.dart';

enum NewPasswordStatus {
  /// Waiting for a password typed twice.
  editing,

  /// The password is being saved.
  saving,

  /// The password was saved.
  saved,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class NewPasswordState extends Equatable {
  const new({
    this.status = NewPasswordStatus.editing,
    this.matches = false,
    this.mismatch = false,
  });

  final NewPasswordStatus status;

  /// A password is typed and the confirmation is the same text.
  final bool matches;

  /// The confirmation differs from the password. Nothing typed in the
  /// confirmation yet is not a mismatch.
  final bool mismatch;

  /// Whether the password can be saved.
  bool get isValid => matches;

  NewPasswordState copyWith({NewPasswordStatus? status}) {
    return NewPasswordState(
      status: status ?? this.status,
      matches: matches,
      mismatch: mismatch,
    );
  }

  @override
  List<Object> get props => [status, matches, mismatch];
}
