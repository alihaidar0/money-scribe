part of 'csv_import_bloc.dart';

sealed class CsvImportEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: open the file picker.
final class CsvImportStarted extends CsvImportEvent {
  const new();
}

/// The user pressed Choose another file, or Choose a file.
final class CsvFileRequested extends CsvImportEvent {
  const new();
}

/// The user pressed Try again after the check of the file failed.
final class CsvCheckRequested extends CsvImportEvent {
  const new();
}

/// The user pressed Import, or Try again after the import failed.
final class CsvImportConfirmed extends CsvImportEvent {
  const new();
}
