import 'package:equatable/equatable.dart';

/// What an export of CSV files can hold.
enum CsvDataKind { transactions, debts, salaryMonths }

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

/// A file the person chose to import, before anything is imported.
final class CsvFile extends Equatable {
  const new({required this.name, required this.rows});

  final String name;

  /// How many rows of data it has.
  final int rows;

  @override
  List<Object> get props => [name, rows];
}

/// What was wrong with a row of a file.
enum CsvProblemKind { invalidAmount, missingDate }

/// A row of the file that was not imported.
final class CsvProblem extends Equatable {
  const new({required this.row, required this.kind});

  /// The number of the row in the file.
  final int row;
  final CsvProblemKind kind;

  @override
  List<Object> get props => [row, kind];
}

/// How an import went: the rows that were added and those that were skipped,
/// each with its problem.
final class CsvImportResult extends Equatable {
  const new({required this.imported, this.problems = const []});

  final int imported;
  final List<CsvProblem> problems;

  /// How many rows were skipped.
  int get skipped => problems.length;

  @override
  List<Object> get props => [imported, problems];
}
