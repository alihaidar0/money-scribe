import 'dart:convert';

import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

/// One kind of data as the server exports and imports it: its name on the
/// wire, the file it has in a `.zip`, and its columns, with how each cell is
/// read. The values are in the order a file of several kinds holds them.
enum CsvDataset {
  accounts(
    CsvDataKind.accounts,
    'accounts',
    columns: ['name', 'kind'],
    textColumns: {'name'},
  ),

  categories(
    CsvDataKind.categories,
    'categories',
    columns: ['name', 'icon'],
    textColumns: {'name'},
  ),

  transactions(
    CsvDataKind.transactions,
    'transactions',
    dayColumn: 'date',
    columns: [
      'date',
      'kind',
      'amount',
      'currency',
      'category_key',
      'category_name',
      'account_name',
      'note',
    ],
    textColumns: {'category_name', 'account_name', 'note'},
    amountColumns: {'amount'},
  ),

  debts(
    CsvDataKind.debts,
    'debts',
    dayColumn: 'start_date',
    columns: [
      'direction',
      'person',
      'amount',
      'currency',
      'start_date',
      'due_date',
      'note',
      'repayments',
    ],
    textColumns: {'person', 'note'},
    jsonColumns: {'repayments'},
    amountColumns: {'amount'},
  ),

  salaryMonths(
    CsvDataKind.salaryMonths,
    'salary_months',
    columns: [
      'month',
      'currency',
      'base_salary',
      'food_per_day',
      'working_days_in_month',
      'working_hours_in_month',
      'extra_hours',
      'tax_rate',
      'payment_mode',
      'working_days_first_half',
      'first_pay_day',
      'second_pay_day',
      'fixed_items',
    ],
    jsonColumns: {'fixed_items'},
    amountColumns: {'base_salary', 'food_per_day'},
    twoDecimalColumns: {'extra_hours', 'tax_rate'},
  );

  new(
    this.kind,
    this.wireName, {
    required this.columns,
    this.dayColumn,
    this.textColumns = const {},
    this.jsonColumns = const {},
    this.amountColumns = const {},
    this.twoDecimalColumns = const {},
  });

  static CsvDataset of(CsvDataKind kind) => switch (kind) {
    CsvDataKind.accounts => accounts,
    CsvDataKind.categories => categories,
    CsvDataKind.transactions => transactions,
    CsvDataKind.debts => debts,
    CsvDataKind.salaryMonths => salaryMonths,
  };

  final CsvDataKind kind;

  /// `transactions`, `debts` or `salary_months`.
  final String wireName;

  /// The columns of the export, in its order.
  final List<String> columns;

  /// The column of the day a row is for, or `null` for a kind with no day.
  final String? dayColumn;

  /// Text a person typed: a spreadsheet could read it as a formula, so the
  /// export may have put one `'` in front.
  final Set<String> textColumns;

  /// A JSON array in a cell.
  final Set<String> jsonColumns;

  /// An amount with the digits of the row's currency.
  final Set<String> amountColumns;

  /// A number with exactly two decimals (hours, a percent).
  final Set<String> twoDecimalColumns;

  /// The name of its file inside a `.zip`.
  String get fileName => '$wireName.csv';

  /// Whether a header row names every column of the kind. Other columns are
  /// allowed, and left out of the import.
  bool matches(List<String> header) => columns.every(header.contains);

  /// The dataset a header row belongs to: the one whose columns it has
  /// exactly, else the only one whose columns it has. `null` when it has none,
  /// or when it could be several (a header with the columns of two kinds and
  /// more): the person is told the file is not an export rather than having it
  /// imported as the wrong kind.
  static CsvDataset? forHeader(List<String> header) {
    final matching = values
        .where((dataset) => dataset.matches(header))
        .toList();
    for (final dataset in matching) {
      if (dataset.columns.length == header.length) return dataset;
    }
    return matching.length == 1 ? matching.single : null;
  }

  /// The cells of a row to send: the columns of the kind only, an empty cell
  /// left out, a JSON cell as its list, a number with the trailing zeros a
  /// spreadsheet dropped, and the `'` the export put in front of a formula
  /// removed. Nothing is rounded or trimmed: the server says what is wrong.
  Map<String, Object> cellsOf(Map<String, String> row) {
    final currency = Currency.tryFromCode(row['currency'] ?? '');
    final cells = <String, Object>{};
    for (final column in columns) {
      final value = row[column];
      if (value == null || value.isEmpty) continue;
      if (jsonColumns.contains(column)) {
        cells[column] = _jsonList(value) ?? value;
      } else if (textColumns.contains(column)) {
        cells[column] = withoutFormulaGuard(value);
      } else if (twoDecimalColumns.contains(column)) {
        cells[column] = padDecimals(value, 2);
      } else if (amountColumns.contains(column) && currency != null) {
        cells[column] = padDecimals(value, currency.fractionDigits);
      } else {
        cells[column] = value;
      }
    }
    return cells;
  }

  /// The day a row is for, as the cell writes it (an empty cell is a day of its
  /// own), or `null` for a kind with no day.
  String? dayOf(Map<String, String> row) {
    final column = dayColumn;
    return column == null ? null : (row[column] ?? '').trim();
  }

  /// A JSON array, or `null` when the cell is not one; the server then says
  /// the row is wrong.
  static List<Object?>? _jsonList(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is List<Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static final RegExp _plainNumber = RegExp(r'^-?\d+(\.\d*)?$');

  /// [value] with trailing zeros up to [digits] decimals (`12.5` is `12.50`,
  /// `12` is `12.00`). A value that is not a plain number, or has more
  /// decimals, is left as it is: it is never rounded.
  static String padDecimals(String value, int digits) {
    if (!_plainNumber.hasMatch(value)) return value;
    final dot = value.indexOf('.');
    final decimals = dot < 0 ? 0 : value.length - dot - 1;
    if (decimals >= digits) return value;
    if (dot < 0) return digits == 0 ? value : '$value.${'0' * digits}';
    return '$value${'0' * (digits - decimals)}';
  }

  static final RegExp _guardedFormula = RegExp(r"^'(?='*[=+\-@\t\r\n])");

  /// [value] without the one `'` the export puts in front of a cell that a
  /// spreadsheet could read as a formula: removed when the rest starts with
  /// any number of `'` and then `=`, `+`, `-`, `@`, a tab or a line break.
  static String withoutFormulaGuard(String value) {
    return _guardedFormula.hasMatch(value) ? value.substring(1) : value;
  }
}
