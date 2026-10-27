part of 'csv_export_password_bloc.dart';

sealed class CsvExportPasswordEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The user typed the password.
final class CsvExportPasswordEdited extends CsvExportPasswordEvent {
  const new(this.password);

  final String password;

  @override
  List<Object?> get props => [password];
}

/// The user pressed Export.
final class CsvExportPasswordSubmitted extends CsvExportPasswordEvent {
  const new();
}

/// A second of the wait the server asked for went by.
final class _CsvExportWaitTicked extends CsvExportPasswordEvent {
  const new(this.secondsLeft);

  final int secondsLeft;

  @override
  List<Object?> get props => [secondsLeft];
}
