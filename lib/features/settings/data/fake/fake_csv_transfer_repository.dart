import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

/// CSV transfer that only pretends, until the files can be read and shared:
/// it makes no file, "chooses" invented ones one after the other, and
/// "imports" them. It follows the demo panel's slow, failing and offline
/// answers.
class FakeCsvTransferRepository implements CsvTransferRepository {
  new({required this._demo});

  /// The files the picker offers, one after the other.
  static const files = [
    CsvFile(name: 'transactions.csv', rows: 42),
    CsvFile(name: 'debts.csv', rows: 12),
  ];

  /// The rows of [files] that cannot be read.
  static const problems = [
    CsvProblem(row: 7, kind: CsvProblemKind.invalidAmount),
    CsvProblem(row: 19, kind: CsvProblemKind.missingDate),
  ];

  final DemoController _demo;

  var _next = 0;

  /// What was asked to export last, or `null` before the first export.
  CsvExportRequest? lastExport;

  @override
  Future<void> export(CsvExportRequest request) async {
    await _demo.simulateSave();
    lastExport = request;
  }

  @override
  Future<CsvFile?> chooseFile() async {
    await _demo.simulateRequest();
    return files[_next++ % files.length];
  }

  @override
  Future<CsvImportResult> import(CsvFile file) async {
    await _demo.simulateSave();
    // The first file has two rows that cannot be read.
    return file == files.first
        ? CsvImportResult(
            imported: file.rows - problems.length,
            problems: problems,
          )
        : CsvImportResult(imported: file.rows);
  }
}
