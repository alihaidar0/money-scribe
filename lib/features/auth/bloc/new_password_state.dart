part of 'new_password_bloc.dart';

enum NewPasswordStatus {
  /// Waiting for a password that follows the rules.
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
    this.hasMinLength = false,
    this.hasNumber = false,
    this.matches = false,
  });

  final NewPasswordStatus status;

  /// The rules of the checklist under the fields.
  final bool hasMinLength;
  final bool hasNumber;
  final bool matches;

  /// Whether the password follows every rule and can be saved.
  bool get isValid => hasMinLength && hasNumber && matches;

  NewPasswordState copyWith({NewPasswordStatus? status}) {
    return NewPasswordState(
      status: status ?? this.status,
      hasMinLength: hasMinLength,
      hasNumber: hasNumber,
      matches: matches,
    );
  }

  @override
  List<Object> get props => [status, hasMinLength, hasNumber, matches];
}
