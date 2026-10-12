part of 'change_password_bloc.dart';

enum ChangePasswordStatus {
  /// The person is typing.
  editing,

  /// The new password is being saved.
  saving,

  /// The new password was saved.
  saved,

  /// The current password is not the password.
  wrongCurrent,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class ChangePasswordState extends Equatable {
  const new({
    this.status = ChangePasswordStatus.editing,
    this.current = '',
    this.next = '',
    this.confirmation = '',
  });

  final ChangePasswordStatus status;
  final String current;
  final String next;
  final String confirmation;

  /// Whether the new password is long enough.
  bool get hasMinLength => next.length >= ChangePasswordBloc.minLength;

  /// Whether the confirmation differs from the new password. Nothing typed in
  /// the confirmation yet is not a mismatch.
  bool get mismatch => confirmation.isNotEmpty && confirmation != next;

  /// Whether the form can be saved.
  bool get isValid =>
      current.isNotEmpty && hasMinLength && confirmation == next;

  ChangePasswordState copyWith({ChangePasswordStatus? status}) {
    return ChangePasswordState(
      status: status ?? this.status,
      current: current,
      next: next,
      confirmation: confirmation,
    );
  }

  @override
  List<Object> get props => [status, current, next, confirmation];
}
