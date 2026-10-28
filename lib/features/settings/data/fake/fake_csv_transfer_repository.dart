import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

/// CSV transfer that only pretends, until the server exists: it makes no
/// file, "chooses" invented ones one after the other, and "imports" them. It
/// follows the demo panel's slow, failing and offline answers; a wrong
/// password follows the sign-in choice "Wrong password", and the lock the
/// password-change choice "Too many attempts", because the server shares that
/// lock.
class FakeCsvTransferRepository implements CsvTransferRepository {
  new({required this._demo});

  /// The files the picker offers, one after the other: a file of transactions,
  /// one of debts, and an export of several kinds. The choice after them is a
  /// file that is not an export of the app.
  static final List<CsvFile> files = [
    _file('transactions.csv', CsvDataKind.transactions, 42),
    _file('debts.csv', CsvDataKind.debts, 12),
    CsvFile(
      name: 'money-scribe-export.zip',
      parts: [
        _part(CsvDataKind.accounts, 3),
        _part(CsvDataKind.categories, 2),
        _part(CsvDataKind.transactions, 20),
      ],
    ),
  ];

  /// The rows of the export of several kinds the import skips: an account the
  /// person already has, and a category named like a built-in one.
  static const zipProblems = [
    CsvProblem(
      kind: CsvDataKind.accounts,
      row: 3,
      reason: CsvProblemReason.duplicate,
    ),
    CsvProblem(
      kind: CsvDataKind.categories,
      row: 2,
      reason: CsvProblemReason.nameTaken,
    ),
  ];

  /// The rows of the first file the import skips, though the check found
  /// nothing: the check is only an estimate.
  static const problems = [
    CsvProblem(
      kind: CsvDataKind.transactions,
      row: 7,
      reason: CsvProblemReason.invalidAmount,
    ),
    CsvProblem(
      kind: CsvDataKind.transactions,
      row: 19,
      reason: CsvProblemReason.missingDate,
    ),
    CsvProblem(
      kind: CsvDataKind.transactions,
      row: 23,
      reason: CsvProblemReason.duplicate,
    ),
    CsvProblem(
      kind: CsvDataKind.transactions,
      row: 31,
      reason: CsvProblemReason.unknownAccount,
    ),
  ];

  /// How long the lock lasts after too many wrong passwords.
  static const lockDuration = Duration(minutes: 15);

  final DemoController _demo;

  var _next = 0;

  /// What was exported last, or `null` before the first export.
  CsvExportRequest? lastExport;

  @override
  Future<void> export(
    CsvExportRequest request, {
    required String password,
  }) async {
    await _demo.simulateSave();
    if (_demo.settings.signIn == DemoSignIn.wrongPassword) {
      throw const CsvExportRefusedException();
    }
    switch (_demo.settings.passwordChange) {
      case DemoPasswordChange.locked:
        throw const TooManyRequestsException(lockDuration);
      case DemoPasswordChange.unavailable:
        throw const ServiceUnavailableException();
      case DemoPasswordChange.accepted || DemoPasswordChange.passwordRefused:
        break;
    }
    lastExport = request;
  }

  @override
  Future<CsvFile?> chooseFile() async {
    await _demo.simulateRequest();
    final choice = _next++ % (files.length + 1);
    if (choice == files.length) {
      throw const CsvFileException(CsvFileIssue.unknownColumns);
    }
    return files[choice];
  }

  @override
  Future<CsvImportResult> check(CsvFile file) async {
    await _demo.simulateRequest();
    return CsvImportResult(imported: file.rows);
  }

  @override
  Future<CsvImportResult> import(
    CsvFile file, {
    void Function(int rowsDone)? onProgress,
  }) async {
    await _demo.simulateSave();
    onProgress?.call(file.rows);
    // The first file, and the export of several kinds, have rows the check did
    // not see.
    return switch (files.indexOf(file)) {
      0 => CsvImportResult(
        imported: file.rows - problems.length,
        problems: problems,
      ),
      2 => CsvImportResult(
        imported: file.rows - zipProblems.length,
        problems: zipProblems,
      ),
      _ => CsvImportResult(imported: file.rows),
    };
  }

  /// A file of [rows] invented rows of [kind].
  static CsvFile _file(String name, CsvDataKind kind, int rows) {
    return CsvFile(name: name, parts: [_part(kind, rows)]);
  }

  static CsvFilePart _part(CsvDataKind kind, int rows) {
    return CsvFilePart(
      kind: kind,
      records: [
        for (var row = 2; row < rows + 2; row++)
          CsvRecord(row: row, cells: {'note': 'Row $row'}),
      ],
    );
  }
}
