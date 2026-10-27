import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

/// Gets the data out of the app as CSV files and back in: creating the file
/// and sharing it, choosing a file, checking it and importing its rows. Every
/// method that reaches the server can throw a `DataException` when it cannot
/// be reached, fails, is busy, or asks to wait (`TooManyRequestsException`).
abstract interface class CsvTransferRepository {
  /// Creates the file of [request] on the server, after it checked
  /// [password], and opens the share sheet; the file is deleted from the
  /// phone afterwards. Throws `CsvExportRefusedException` for a wrong
  /// password.
  Future<void> export(CsvExportRequest request, {required String password});

  /// Opens the system file picker for a `.csv` or a `.zip` file and reads it.
  /// `null` when the person chose nothing. Throws `CsvFileException` when the
  /// file cannot be imported at all.
  Future<CsvFile?> chooseFile();

  /// What importing [file] would do, without writing anything. It is an
  /// estimate: a row can still be refused by the import, for example as a
  /// repeat of a row sent earlier in the same file.
  Future<CsvImportResult> check(CsvFile file);

  /// Imports the rows of [file]. A row that cannot be added is skipped, with
  /// its problem in the result. [onProgress] hears how many rows have been
  /// sent. Calling it again for the same file after a failure goes on where
  /// it stopped, so no row is sent twice.
  Future<CsvImportResult> import(
    CsvFile file, {
    void Function(int rowsDone)? onProgress,
  });
}
