import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:money_scribe/features/settings/data/csv/csv_dataset.dart';
import 'package:money_scribe/features/settings/data/csv/csv_text.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

/// Reads a file the person chose into the rows to import, and refuses it
/// before anything is sent when it cannot be imported ([CsvFileException]).
///
/// A CSV file is one kind of data, known by its header row. A `.zip` holds up
/// to one file per kind, known by its name (`transactions.csv`, `debts.csv`,
/// `salary_months.csv`, in any folder), and is read in that order. A file may
/// start with a byte order mark and use `,` or `;` between cells.
final class CsvFileReader {
  const new({
    this.maxFileBytes = defaultMaxFileBytes,
    this.maxUnzippedBytes = defaultMaxUnzippedBytes,
    this.maxRows = defaultMaxRows,
  });

  /// A chosen file larger than this is refused.
  static const int defaultMaxFileBytes = 5 * 1024 * 1024;

  /// The CSV files of a `.zip` together may not be larger than this once
  /// unzipped, so a small archive cannot fill the phone's memory.
  static const int defaultMaxUnzippedBytes = 20 * 1024 * 1024;

  /// The most rows one import takes: each 500 rows are a check and an import
  /// call, and the server takes 120 calls an hour.
  static const defaultMaxRows = 20000;

  final int maxFileBytes;
  final int maxUnzippedBytes;
  final int maxRows;

  CsvFile read(String name, Uint8List bytes) {
    if (bytes.length > maxFileBytes) {
      throw const CsvFileException(CsvFileIssue.tooLarge);
    }
    final parts = _isZip(name, bytes)
        ? _readZip(bytes)
        : [_readCsv(bytes, expected: null)];
    final file = CsvFile(name: name, parts: parts);
    if (file.rows == 0) throw const CsvFileException(CsvFileIssue.noRows);
    if (file.rows > maxRows) {
      throw CsvFileException(CsvFileIssue.tooManyRows, limit: maxRows);
    }
    return file;
  }

  static bool _isZip(String name, Uint8List bytes) {
    // A zip starts with "PK\x03\x04"; the name decides for an empty one.
    if (bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4b &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04) {
      return true;
    }
    return name.toLowerCase().endsWith('.zip');
  }

  List<CsvFilePart> _readZip(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const CsvFileException(CsvFileIssue.unreadable);
    }
    // A broken zip reads as one with nothing in it.
    if (archive.files.isEmpty) {
      throw const CsvFileException(CsvFileIssue.unreadable);
    }
    final byName = <String, ArchiveFile>{
      for (final entry in archive.files)
        if (entry.isFile) _baseName(entry.name).toLowerCase(): entry,
    };
    final found = [
      for (final dataset in CsvDataset.values)
        if (byName[dataset.fileName] case final entry?) (dataset, entry),
    ];
    if (found.isEmpty) {
      throw const CsvFileException(CsvFileIssue.unknownColumns);
    }
    final declared = found.fold(0, (sum, item) => sum + item.$2.size);
    if (declared > maxUnzippedBytes) {
      throw const CsvFileException(CsvFileIssue.tooLarge);
    }

    var unzipped = 0;
    final parts = <CsvFilePart>[];
    for (final (dataset, entry) in found) {
      final Uint8List content;
      try {
        content = entry.readBytes() ?? Uint8List(0);
      } on Object {
        throw const CsvFileException(CsvFileIssue.unreadable);
      }
      unzipped += content.length;
      // The sizes in a zip are what it says, not what it holds.
      if (unzipped > maxUnzippedBytes) {
        throw const CsvFileException(CsvFileIssue.tooLarge);
      }
      parts.add(_readCsv(content, expected: dataset));
    }
    return parts;
  }

  static final _byteOrderMark = String.fromCharCode(0xFEFF);

  static String _baseName(String path) => path.split(RegExp(r'[/\\]')).last;

  /// The rows of one CSV file. [expected] is the kind its name says, in a
  /// `.zip`; a single file is known by its header.
  CsvFilePart _readCsv(Uint8List bytes, {required CsvDataset? expected}) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const CsvFileException(CsvFileIssue.unreadable);
    }
    final body = text.startsWith(_byteOrderMark) ? text.substring(1) : text;

    for (final separator in const [',', ';']) {
      final List<List<String>> rows;
      try {
        rows = parseCsvText(body, separator: separator);
      } on FormatException {
        throw const CsvFileException(CsvFileIssue.unreadable);
      }
      if (rows.isEmpty) continue;
      final header = [for (final cell in rows.first) cell.trim()];
      final dataset = expected ?? CsvDataset.forHeader(header);
      if (dataset == null || !dataset.matches(header)) continue;
      return CsvFilePart(
        kind: dataset.kind,
        records: _records(dataset, header, rows),
      );
    }
    throw const CsvFileException(CsvFileIssue.unknownColumns);
  }

  static List<CsvRecord> _records(
    CsvDataset dataset,
    List<String> header,
    List<List<String>> rows,
  ) {
    final records = <CsvRecord>[];
    for (var index = 1; index < rows.length; index++) {
      final cells = rows[index];
      // A spreadsheet saves an empty row as a line with nothing, or with the
      // separators only.
      if (cells.every((cell) => cell.isEmpty)) continue;
      final byColumn = <String, String>{
        for (var column = 0; column < header.length; column++)
          header[column]: column < cells.length ? cells[column] : '',
      };
      records.add(
        // The header is row 1, as a spreadsheet counts.
        CsvRecord(
          row: index + 1,
          cells: dataset.cellsOf(byColumn),
          day: dataset.dayOf(byColumn),
        ),
      );
    }
    return records;
  }
}
