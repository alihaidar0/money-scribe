part of 'csv_import_bloc.dart';

enum CsvImportStatus {
  /// The file picker is open.
  choosing,

  /// No file is chosen.
  noFile,

  /// A file is chosen and can be imported.
  ready,

  /// The rows are being imported.
  importing,

  /// The import is over: the result is shown.
  imported,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class CsvImportState extends Equatable {
  const new({
    this.status = CsvImportStatus.choosing,
    this.file,
    this.result,
    this.failedAction,
  });

  final CsvImportStatus status;

  /// The file that is chosen.
  final CsvFile? file;

  /// How the import went, once it is over.
  final CsvImportResult? result;

  /// What failed, so Try again can do it again.
  final CsvImportEvent? failedAction;

  CsvImportState copyWith({
    CsvImportStatus? status,
    CsvFile? file,
    CsvImportResult? result,
    CsvImportEvent? failedAction,
  }) {
    return CsvImportState(
      status: status ?? this.status,
      file: file ?? this.file,
      result: result ?? this.result,
      failedAction: failedAction ?? this.failedAction,
    );
  }

  @override
  List<Object?> get props => [status, file, result, failedAction];
}
