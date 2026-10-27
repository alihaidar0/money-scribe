import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/ids/uuid_v4.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';
import 'package:money_scribe/features/settings/data/csv/csv_dataset.dart';
import 'package:money_scribe/features/settings/data/csv/csv_device.dart';
import 'package:money_scribe/features/settings/data/csv/csv_file_reader.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

/// The CSV export and import on the server: the real [CsvTransferRepository].
///
/// The export asks for the password and answers with the file, which is
/// shared from the app's private cache. The import never uploads the file: the
/// app reads it, then sends its rows as JSON, at most 500 (and well under the
/// server's 1 MB) a call, kind after kind: accounts, categories, transactions,
/// debts, salary months. The rows of one day (a transaction's date, a debt's
/// start date) always go in the same call, because the server compares a row
/// with the records it has written, not with the other rows of its call, so a
/// repeat split between two calls would be written twice. A check sends every
/// call as a dry run; an import sends each call once, with its own
/// `Idempotency-Key`, kept until the call has an answer, so a retry after a
/// lost connection never adds a row twice and an import that stopped goes on
/// where it stopped.
///
/// Both calls are sent by hand: the generated client reads the export as text,
/// which breaks a `.zip`, and its import row keeps only the row number. The
/// body of an import is sent as JSON text, so no interceptor changes a cell
/// (one that looks like a date at midnight, for instance).
class RemoteCsvTransferRepository implements CsvTransferRepository {
  new({
    required this._dio,
    required this._picker,
    required this._sharer,
    this._reader = const CsvFileReader(),
    String Function()? newKey,
  }) : _newKey = newKey ?? generateUuidV4;

  /// The most bytes of rows a call sends; the server takes 1 MB.
  static const int maxBytesPerCall = 900 * 1024;

  static const _exportPath = '/api/v1/exports/';
  static const _importPath = '/api/v1/imports/';

  final Dio _dio;
  final CsvFilePicker _picker;
  final CsvFileSharer _sharer;
  final CsvFileReader _reader;
  final String Function() _newKey;

  /// The import under way, so a retry after a failure goes on with it.
  _ImportRun? _run;

  @override
  Future<void> export(
    CsvExportRequest request, {
    required String password,
  }) async {
    final datasets = [
      for (final dataset in CsvDataset.values)
        if (request.kinds.contains(dataset.kind)) dataset,
    ];
    final body = api.ExportRequestRequest(
      kinds: [for (final dataset in datasets) _wire(dataset.kind)],
      // Sent exactly as typed.
      currentPassword: password,
      from: request.from,
      to: request.to,
    );
    final Response<List<int>> answer;
    try {
      answer = await _dio.post<List<int>>(
        _exportPath,
        data: body.toJson(),
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (error) {
      final failure = ApiFailure.from(error);
      if (failure.statusCode == 400 && failure.hasCode('invalid_password')) {
        throw const CsvExportRefusedException();
      }
      throw failure.toDataException();
    }
    final bytes = answer.data;
    if (bytes == null) throw const ServerException();
    final several = datasets.length > 1;
    await _sharer.share(
      Uint8List.fromList(bytes),
      fileName:
          _fileName(answer.headers) ??
          (several
              ? 'money-scribe-export.zip'
              : 'money-scribe-${datasets.single.wireName}.csv'),
      mimeType: several ? 'application/zip' : 'text/csv',
    );
  }

  static final RegExp _attachment = RegExp('filename="([A-Za-z0-9._-]+)"');

  /// The name the server gave the file, when it is a plain one.
  static String? _fileName(Headers headers) {
    final disposition = headers.value('content-disposition');
    if (disposition == null) return null;
    return _attachment.firstMatch(disposition)?.group(1);
  }

  @override
  Future<CsvFile?> chooseFile() async {
    final picked = await _picker.pick(maxBytes: _reader.maxFileBytes);
    if (picked == null) return null;
    return _reader.read(picked.name, picked.bytes);
  }

  @override
  Future<CsvImportResult> check(CsvFile file) async {
    var imported = 0;
    final problems = <CsvProblem>[];
    final created = _CreatedNames(file);
    for (final chunk in _chunks(file)) {
      final answer = await _send(chunk, dryRun: true);
      imported += answer.imported;
      problems.addAll(created.without(chunk, _problems(chunk.kind, answer)));
    }
    return CsvImportResult(imported: imported, problems: problems);
  }

  @override
  Future<CsvImportResult> import(
    CsvFile file, {
    void Function(int rowsDone)? onProgress,
  }) async {
    final run = _run?.file == file ? _run! : _ImportRun(file, _chunks(file));
    _run = run;
    while (run.next < run.chunks.length) {
      final chunk = run.chunks[run.next];
      final key = run.key ??= _newKey();
      final api.ImportResult answer;
      try {
        answer = await _send(chunk, dryRun: false, key: key);
      } on _CallFailed catch (failed) {
        // A refusal no retry changes needs a new key; anything else is sent
        // again with this one.
        if (IdempotencyKeys.isFinal(failed.failure)) run.key = null;
        throw failed.exception;
      }
      run
        ..key = null
        ..next += 1
        ..imported += answer.imported
        ..problems.addAll(_problems(chunk.kind, answer))
        ..rowsDone += chunk.records.length;
      onProgress?.call(run.rowsDone);
    }
    _run = null;
    return CsvImportResult(imported: run.imported, problems: run.problems);
  }

  Future<api.ImportResult> _send(
    _Chunk chunk, {
    required bool dryRun,
    String? key,
  }) async {
    final body = jsonEncode({
      'dataset': CsvDataset.of(chunk.kind).wireName,
      'dry_run': dryRun,
      'rows': [
        for (final record in chunk.records)
          {'row': record.row, ...record.cells},
      ],
    });
    try {
      final answer = await _dio.post<Map<String, dynamic>>(
        _importPath,
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            if (key != null)
              'Idempotency-Key': WriteSafetyHeaders.idempotencyKey(key),
          },
        ),
      );
      final data = answer.data;
      if (data == null) throw const ServerException();
      return api.ImportResult.fromJson(data);
    } on DioException catch (error) {
      final failure = ApiFailure.from(error);
      if (dryRun) throw failure.toDataException();
      throw _CallFailed(failure, failure.toDataException());
      // An answer of another shape fails inside the generated `fromJson`.
      // ignore: avoid_catching_errors
    } on TypeError {
      throw const ServerException();
    }
  }

  /// The rows of [file] in calls: kind after kind, each call at most
  /// [csvRowsPerCall] rows and [maxBytesPerCall] bytes, and a day never split
  /// between two calls unless it alone is more than a call takes.
  static List<_Chunk> _chunks(CsvFile file) {
    final chunks = <_Chunk>[];
    for (final part in file.parts) {
      var records = <CsvRecord>[];
      var bytes = 0;
      void send() {
        if (records.isNotEmpty) chunks.add(_Chunk(part.kind, records));
        records = [];
        bytes = 0;
      }

      for (final group in _byDay(part.records)) {
        final size = [for (final r in group) _size(r)].fold(0, (a, b) => a + b);
        // The group goes whole into the next call when it does not fit this one
        // but fits a call of its own.
        final fits = group.length <= csvRowsPerCall && size <= maxBytesPerCall;
        if (fits &&
            (records.length + group.length > csvRowsPerCall ||
                bytes + size > maxBytesPerCall)) {
          send();
        }
        for (final record in group) {
          final recordSize = _size(record);
          if (records.length == csvRowsPerCall ||
              (records.isNotEmpty && bytes + recordSize > maxBytesPerCall)) {
            send();
          }
          records.add(record);
          bytes += recordSize;
        }
      }
      send();
    }
    return chunks;
  }

  static int _size(CsvRecord record) =>
      utf8.encode(jsonEncode(record.cells)).length + 32;

  /// The rows grouped by day, in the order the days first appear. A kind with
  /// no day has every row in a group of its own, so they pack freely.
  static List<List<CsvRecord>> _byDay(List<CsvRecord> records) {
    final groups = <String, List<CsvRecord>>{};
    final loose = <List<CsvRecord>>[];
    for (final record in records) {
      final day = record.day;
      if (day == null) {
        loose.add([record]);
      } else {
        (groups[day] ??= []).add(record);
      }
    }
    return [...groups.values, ...loose];
  }

  static List<CsvProblem> _problems(CsvDataKind kind, api.ImportResult answer) {
    return [
      for (final problem in answer.problems)
        CsvProblem(
          kind: kind,
          row: problem.row,
          reason: reasonOf(problem.code, problem.attr),
        ),
    ];
  }

  static const _dateColumns = {'date', 'start_date', 'month'};

  /// What a problem of the server means to the person. A code this version
  /// does not know is [CsvProblemReason.other]. [attr] is the field of the row,
  /// with the place of a nested one (`repayments.0.date`).
  static CsvProblemReason reasonOf(String code, String? attr) {
    final field = attr?.split('.').last;
    if (code == 'required' && _dateColumns.contains(field)) {
      return CsvProblemReason.missingDate;
    }
    if (code == 'required' && attr == 'icon') {
      return CsvProblemReason.missingIcon;
    }
    return switch (code) {
      'name_taken' => CsvProblemReason.nameTaken,
      'invalid_amount' => CsvProblemReason.invalidAmount,
      'duplicate' => CsvProblemReason.duplicate,
      'unknown_category' => CsvProblemReason.unknownCategory,
      'unknown_account' => CsvProblemReason.unknownAccount,
      _ when code.endsWith('_limit_reached') => CsvProblemReason.limitReached,
      _ => CsvProblemReason.other,
    };
  }

  static api.DatasetEnum _wire(CsvDataKind kind) => switch (kind) {
    CsvDataKind.accounts => api.DatasetEnum.accounts,
    CsvDataKind.categories => api.DatasetEnum.categories,
    CsvDataKind.transactions => api.DatasetEnum.transactions,
    CsvDataKind.debts => api.DatasetEnum.debts,
    CsvDataKind.salaryMonths => api.DatasetEnum.salaryMonths,
  };
}

/// One call of an import: up to 500 rows of one kind.
final class _Chunk {
  const new(this.kind, this.records);

  final CsvDataKind kind;
  final List<CsvRecord> records;
}

/// An import under way: the calls, the next one to send and its key while it
/// has no answer, and what the calls before it answered.
final class _ImportRun {
  new(this.file, this.chunks);

  final CsvFile file;
  final List<_Chunk> chunks;
  int next = 0;
  String? key;
  int imported = 0;
  int rowsDone = 0;
  final problems = <CsvProblem>[];
}

/// A real import call failed: the [failure] decides whether its key is kept,
/// the [exception] is what the screen hears.
final class _CallFailed implements Exception {
  const new(this.failure, this.exception);

  final ApiFailure failure;
  final DataException exception;
}

/// The accounts and categories a file creates itself. The check of its
/// transactions runs before they exist, so it reports every account and
/// category the file is about to create as unknown: those problems are left
/// out of the estimate. Names are compared without regard to case, with the
/// spaces around them trimmed; the real import has the last word.
final class _CreatedNames {
  new(CsvFile file)
    : _accounts = _names(file, CsvDataKind.accounts),
      _categories = _names(file, CsvDataKind.categories);

  final Set<String> _accounts;
  final Set<String> _categories;

  static Set<String> _names(CsvFile file, CsvDataKind kind) {
    return {
      for (final part in file.parts)
        if (part.kind == kind)
          for (final record in part.records)
            if (record.cells['name'] case final String name) _key(name),
    };
  }

  static String _key(String name) => name.trim().toLowerCase();

  /// [problems] of the check of [chunk], without those about a name the file
  /// creates.
  List<CsvProblem> without(_Chunk chunk, List<CsvProblem> problems) {
    if (chunk.kind != CsvDataKind.transactions) return problems;
    final cells = {for (final r in chunk.records) r.row: r.cells};
    return [
      for (final problem in problems)
        if (!_isCreated(problem, cells[problem.row])) problem,
    ];
  }

  bool _isCreated(CsvProblem problem, Map<String, Object>? cells) {
    if (cells == null) return false;
    final (names, column) = switch (problem.reason) {
      CsvProblemReason.unknownAccount => (_accounts, 'account_name'),
      CsvProblemReason.unknownCategory => (_categories, 'category_name'),
      _ => (const <String>{}, ''),
    };
    final value = cells[column];
    return value is String && names.contains(_key(value));
  }
}
