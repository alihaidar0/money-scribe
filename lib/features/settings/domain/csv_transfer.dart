import 'package:equatable/equatable.dart';

/// What an export of CSV files can hold, in the order a file of several kinds
/// holds them and an import sends them: the accounts and the custom categories
/// first, because the transactions name them.
enum CsvDataKind { accounts, categories, transactions, debts, salaryMonths }

/// The most rows one call of an import sends.
const int csvRowsPerCall = 500;

/// Which days an export covers.
enum CsvPeriod { allTime, thisYear, custom }

/// What to export: the kinds of data and the days they cover. A period that is
/// not "all time" has its first and last day.
final class CsvExportRequest extends Equatable {
  const new({required this.kinds, required this.period, this.from, this.to});

  final Set<CsvDataKind> kinds;
  final CsvPeriod period;
  final DateTime? from;
  final DateTime? to;

  @override
  List<Object?> get props => [kinds, period, from, to];
}

/// The server refused the export because the password is not the password of
/// the account. Too many wrong ones is a `TooManyRequestsException` with the
/// wait.
final class CsvExportRefusedException implements Exception {
  const new();

  @override
  String toString() => 'CsvExportRefusedException';
}

/// One row of a file to import: its number in the file (the header is row 1,
/// as a spreadsheet counts) and its cells by column. An empty cell is left
/// out; a JSON cell is a list.
final class CsvRecord extends Equatable {
  const new({required this.row, required this.cells, this.day});

  final int row;
  final Map<String, Object> cells;

  /// The day the row is for, as the file writes it, when the kind has one (a
  /// transaction's `date`, a debt's `start_date`): rows of a day are sent in
  /// the same call, so the server sees a repeat of a row.
  final String? day;

  @override
  List<Object?> get props => [row, cells, day];
}

/// The rows of one kind of data in a file.
final class CsvFilePart extends Equatable {
  const new({required this.kind, required this.records});

  final CsvDataKind kind;
  final List<CsvRecord> records;

  /// How many days have more rows than one call takes, so a repeat of a row
  /// inside such a day may be missed.
  int get crowdedDays {
    final perDay = <String, int>{};
    for (final record in records) {
      final day = record.day;
      if (day != null) perDay[day] = (perDay[day] ?? 0) + 1;
    }
    return perDay.values.where((rows) => rows > csvRowsPerCall).length;
  }

  @override
  List<Object> get props => [kind, records];
}

/// A file the person chose to import, read and checked, before anything is
/// sent: a CSV file is one part, a `.zip` up to one part per kind.
final class CsvFile extends Equatable {
  const new({required this.name, required this.parts});

  final String name;
  final List<CsvFilePart> parts;

  /// How many rows of data it has.
  int get rows => parts.fold(0, (sum, part) => sum + part.records.length);

  /// How many days, in all its parts, have more rows than one call takes.
  int get crowdedDays => parts.fold(0, (sum, part) => sum + part.crowdedDays);

  @override
  List<Object> get props => [name, parts];
}

/// Why a chosen file cannot be imported at all.
enum CsvFileIssue {
  /// Not a CSV or a `.zip` file that can be read.
  unreadable,

  /// The first row does not have the columns of a Money Scribe export, or a
  /// `.zip` has none of its files.
  unknownColumns,

  /// It has the column names only.
  noRows,

  /// More rows than one import takes ([CsvFileException.limit]).
  tooManyRows,

  /// Larger than the app reads, once unzipped.
  tooLarge,
}

/// The chosen file cannot be imported; nothing was sent.
final class CsvFileException implements Exception {
  const new(this.issue, {this.limit});

  final CsvFileIssue issue;

  /// The most rows a file may have, for [CsvFileIssue.tooManyRows].
  final int? limit;

  @override
  String toString() => 'CsvFileException($issue)';
}

/// Why a row of a file was not imported.
enum CsvProblemReason {
  /// The date of the row is missing.
  missingDate,

  /// The amount is not a valid amount.
  invalidAmount,

  /// A record with the same content already exists.
  duplicate,

  /// No category has the row's category.
  unknownCategory,

  /// No account has the row's account name.
  unknownAccount,

  /// The account holds as many records of this kind as it may.
  limitReached,

  /// The name of a category is the name of a built-in one.
  nameTaken,

  /// A category has no icon.
  missingIcon,

  /// Any other problem, or one this version of the app does not know.
  other,
}

/// A row of the file that was not imported, or that a check says would not
/// be.
final class CsvProblem extends Equatable {
  const new({required this.kind, required this.row, required this.reason});

  /// The part of the file the row is in.
  final CsvDataKind kind;

  /// The number of the row in its part.
  final int row;
  final CsvProblemReason reason;

  @override
  List<Object> get props => [kind, row, reason];
}

/// How an import went, or what a check says it would do: the rows that were
/// (or would be) added, and those that were (or would be) skipped, each with
/// its problem.
final class CsvImportResult extends Equatable {
  const new({required this.imported, this.problems = const []});

  final int imported;
  final List<CsvProblem> problems;

  /// How many rows were skipped.
  int get skipped => problems.length;

  /// Whether the problems are in more than one part, so each says its part.
  bool get spansParts =>
      problems.map((problem) => problem.kind).toSet().length > 1;

  @override
  List<Object> get props => [imported, problems];
}
