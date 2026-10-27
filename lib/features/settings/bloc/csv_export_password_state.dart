part of 'csv_export_password_bloc.dart';

enum CsvExportPasswordStatus {
  /// The person is typing the password.
  editing,

  /// The password is being checked and the file made.
  exporting,

  /// The file was made and shared.
  done,

  /// The password is not the password of the account.
  wrongPassword,

  /// Too many wrong passwords, or too many exports: the field and the button
  /// wait, see [CsvExportPasswordState.waitSecondsLeft].
  waiting,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class CsvExportPasswordState extends Equatable {
  const new({
    this.status = CsvExportPasswordStatus.editing,
    this.password = '',
    this.waitSecondsLeft = 0,
  });

  final CsvExportPasswordStatus status;
  final String password;

  /// Seconds until the password can be sent again, while [status] is
  /// `waiting`.
  final int waitSecondsLeft;

  CsvExportPasswordState copyWith({
    CsvExportPasswordStatus? status,
    int? waitSecondsLeft,
  }) {
    return CsvExportPasswordState(
      status: status ?? this.status,
      password: password,
      waitSecondsLeft: waitSecondsLeft ?? this.waitSecondsLeft,
    );
  }

  @override
  List<Object?> get props => [status, password, waitSecondsLeft];
}
