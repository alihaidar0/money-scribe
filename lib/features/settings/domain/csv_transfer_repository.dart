import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

/// Gets the data out of the app as CSV files and back in: creating the file
/// and sharing it, choosing a file, and importing its rows. Every method can
/// throw a `DataException` when the server cannot be reached or fails.
abstract interface class CsvTransferRepository {
  /// Creates the file of [request] and opens the share sheet.
  Future<void> export(CsvExportRequest request);

  /// Opens the system file picker. `null` when the person chose nothing.
  Future<CsvFile?> chooseFile();

  /// Imports the rows of [file]. A row that cannot be read is skipped, with
  /// its problem in the result.
  Future<CsvImportResult> import(CsvFile file);
}
