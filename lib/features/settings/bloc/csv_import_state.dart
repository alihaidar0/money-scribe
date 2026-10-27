part of 'csv_import_bloc.dart';

enum CsvImportStatus {
  /// The file picker is open.
  choosing,

  /// No file is chosen.
  noFile,

  /// The chosen file cannot be imported: see [CsvImportState.fileIssue].
  fileProblem,

  /// The file is chosen, and the server is asked what it would import.
  checking,

  /// The file is checked and can be imported: see [CsvImportState.estimate].
  ready,

  /// The rows are being imported: see [CsvImportState.rowsDone].
  importing,

  /// The import is over: the result is shown.
  imported,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed, or asked to wait.
  failure,
}

final class CsvImportState extends Equatable {
  const new({
    this.status = CsvImportStatus.choosing,
    this.file,
    this.fileIssue,
    this.fileLimit,
    this.estimate,
    this.rowsDone = 0,
    this.result,
    this.failedAction,
  });

  final CsvImportStatus status;

  /// The file that is chosen.
  final CsvFile? file;

  /// Why the chosen file cannot be imported, while [status] is `fileProblem`.
  final CsvFileIssue? fileIssue;

  /// The most rows a file may have, for `CsvFileIssue.tooManyRows`.
  final int? fileLimit;

  /// What the check says the import would do.
  final CsvImportResult? estimate;

  /// How many rows of the file have been sent.
  final int rowsDone;

  /// How the import went, once it is over.
  final CsvImportResult? result;

  /// What failed, so Try again can do it again.
  final CsvImportEvent? failedAction;

  CsvImportState copyWith({int? rowsDone}) {
    return CsvImportState(
      status: status,
      file: file,
      fileIssue: fileIssue,
      fileLimit: fileLimit,
      estimate: estimate,
      rowsDone: rowsDone ?? this.rowsDone,
      result: result,
      failedAction: failedAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    file,
    fileIssue,
    fileLimit,
    estimate,
    rowsDone,
    result,
    failedAction,
  ];
}
