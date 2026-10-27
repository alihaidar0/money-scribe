import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/data/csv/csv_device.dart';
import 'package:money_scribe/features/settings/data/remote/remote_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

import '../../../support/fake_http_adapter.dart';
import '../../transactions/data/transactions_json.dart';

class _Picker implements CsvFilePicker {
  PickedFile? file;
  int? maxBytes;

  @override
  Future<PickedFile?> pick({required int maxBytes}) async {
    this.maxBytes = maxBytes;
    return file;
  }
}

class _Sharer implements CsvFileSharer {
  final shared = <({Uint8List bytes, String fileName, String mimeType})>[];

  @override
  Future<void> share(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    shared.add((bytes: bytes, fileName: fileName, mimeType: mimeType));
  }
}

/// A file of [rows] invented transactions, numbered from row 2.
CsvFile _transactions(int rows, {String note = 'Weekly shop'}) {
  return CsvFile(
    name: 'money-scribe-transactions.csv',
    parts: [
      CsvFilePart(
        kind: CsvDataKind.transactions,
        records: [
          for (var row = 2; row < rows + 2; row++)
            CsvRecord(
              row: row,
              day: '2026-10-24',
              cells: {
                'date': '2026-10-24',
                'kind': 'expense',
                'amount': '12.50',
                'currency': 'USD',
                'category_key': 'groceries',
                'account_name': 'Travel card',
                'note': note,
              },
            ),
        ],
      ),
    ],
  );
}

/// Transactions numbered from row 2, one for each of [days], in that order.
CsvFilePart _days(List<String> days) {
  return CsvFilePart(
    kind: CsvDataKind.transactions,
    records: [
      for (var i = 0; i < days.length; i++)
        CsvRecord(
          row: i + 2,
          day: days[i],
          cells: {
            'date': days[i],
            'kind': 'expense',
            'amount': '1.00',
            'currency': 'USD',
            'category_key': 'groceries',
            'account_name': 'Cash',
          },
        ),
    ],
  );
}

Map<String, Object?> _result({
  String dataset = 'transactions',
  bool dryRun = false,
  int imported = 0,
  List<Map<String, Object?>> problems = const [],
}) {
  return {
    'dataset': dataset,
    'dry_run': dryRun,
    'imported': imported,
    'skipped': problems.length,
    'problems': problems,
  };
}

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions) answer;
  late _Picker picker;
  late _Sharer sharer;
  late int keys;

  setUp(() {
    answer = (_) => jsonBody(404);
    server = FakeHttpAdapter((options) => answer(options));
    picker = _Picker();
    sharer = _Sharer();
    keys = 0;
  });

  RemoteCsvTransferRepository build() {
    return RemoteCsvTransferRepository(
      dio: transactionsTestDio(server),
      picker: picker,
      sharer: sharer,
      newKey: () => 'import-key-${++keys}-0000000000',
    );
  }

  Map<String, dynamic> bodyOf(RequestOptions request) {
    final data = request.data;
    return (data is String ? jsonDecode(data) : data) as Map<String, dynamic>;
  }

  /// The number of the first row a call sent.
  int firstRow(RequestOptions request) {
    final rows = bodyOf(request)['rows'] as List<Object?>;
    return (rows.first! as Map<String, Object?>)['row']! as int;
  }

  List<RequestOptions> imports() => [
    for (final r in server.requests)
      if (r.path == '/api/v1/imports/') r,
  ];

  group('export', () {
    final oneKind = CsvExportRequest(
      kinds: const {CsvDataKind.transactions},
      period: CsvPeriod.thisYear,
      from: DateTime(2026),
      to: DateTime(2026, 12, 31),
    );
    final csv = [0xEF, 0xBB, 0xBF, ...utf8.encode('date,kind\r\n')];

    test('sends the choice and the password, and shares the file', () async {
      answer = (_) => ResponseBody.fromBytes(
        csv,
        200,
        headers: {
          Headers.contentTypeHeader: ['text/csv; charset=utf-8'],
          'content-disposition': [
            'attachment; filename="money-scribe-transactions.csv"',
          ],
        },
      );

      await build().export(oneKind, password: ' p@ss word ');

      final request = server.requests.single;
      expect(request.path, '/api/v1/exports/');
      expect(request.method, 'POST');
      expect(bodyOf(request), {
        'kinds': ['transactions'],
        'current_password': ' p@ss word ',
        'from': '2026-01-01',
        'to': '2026-12-31',
      });
      final shared = sharer.shared.single;
      expect(shared.bytes, csv);
      expect(shared.fileName, 'money-scribe-transactions.csv');
      expect(shared.mimeType, 'text/csv');
    });

    test('several kinds are one .zip, in the order of a file', () async {
      final zip = [0x50, 0x4b, 0x03, 0x04, 0, 0xFF];
      answer = (_) => ResponseBody.fromBytes(
        zip,
        200,
        headers: {
          Headers.contentTypeHeader: ['application/zip'],
        },
      );

      await build().export(
        const CsvExportRequest(
          kinds: {CsvDataKind.salaryMonths, CsvDataKind.transactions},
          period: CsvPeriod.allTime,
        ),
        password: 'secret',
      );

      final body = bodyOf(server.requests.single);
      expect(body['kinds'], ['transactions', 'salary_months']);
      expect(body.containsKey('from'), isFalse);
      final shared = sharer.shared.single;
      expect(shared.bytes, zip);
      expect(shared.fileName, 'money-scribe-export.zip');
      expect(shared.mimeType, 'application/zip');
    });

    test('every kind is asked for in the order of a file', () async {
      answer = (_) => ResponseBody.fromBytes([0x50, 0x4b, 0x03, 0x04], 200);

      await build().export(
        CsvExportRequest(
          kinds: CsvDataKind.values.reversed.toSet(),
          period: CsvPeriod.allTime,
        ),
        password: 'secret',
      );

      expect(bodyOf(server.requests.single)['kinds'], [
        'accounts',
        'categories',
        'transactions',
        'debts',
        'salary_months',
      ]);
      expect(sharer.shared.single.fileName, 'money-scribe-export.zip');
    });

    test('accounts alone are one file, named as the server names it', () async {
      answer = (_) => ResponseBody.fromBytes(
        utf8.encode('name,kind\r\n'),
        200,
        headers: {
          'content-disposition': [
            'attachment; filename="money-scribe-accounts.csv"',
          ],
        },
      );

      await build().export(
        const CsvExportRequest(
          kinds: {CsvDataKind.accounts},
          period: CsvPeriod.allTime,
        ),
        password: 'secret',
      );

      expect(bodyOf(server.requests.single)['kinds'], ['accounts']);
      expect(sharer.shared.single.fileName, 'money-scribe-accounts.csv');
      expect(sharer.shared.single.mimeType, 'text/csv');
    });

    test('a wrong password is said, and nothing is shared', () async {
      answer = (_) => jsonBody(
        400,
        errorBody('invalid_password', attr: 'current_password'),
      );

      await expectLater(
        build().export(oneKind, password: 'wrong'),
        throwsA(isA<CsvExportRefusedException>()),
      );
      expect(sharer.shared, isEmpty);
    });

    test('too many attempts wait as long as the server says', () async {
      answer = (_) => jsonBody(429, errorBody('password_attempts_exceeded'), {
        'retry-after': '872',
      });

      await expectLater(
        build().export(oneKind, password: 'wrong'),
        throwsA(
          isA<TooManyRequestsException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 872),
          ),
        ),
      );
    });

    test('a busy server and a lost connection are said', () async {
      answer = (_) => jsonBody(503, errorBody('service_unavailable'));
      await expectLater(
        build().export(oneKind, password: 'p'),
        throwsA(isA<ServiceUnavailableException>()),
      );

      answer = (options) => throw connectionLost(options);
      await expectLater(
        build().export(oneKind, password: 'p'),
        throwsA(isA<NoConnectionException>()),
      );
      expect(sharer.shared, isEmpty);
    });
  });

  group('choosing a file', () {
    test('reads the picked file', () async {
      picker.file = (
        name: 'debts.csv',
        bytes: utf8.encode(
          'direction,person,amount,currency,start_date,due_date,note,'
          'repayments\nlent,Alex,200,USD,2026-10-01,,,[]\n',
        ),
      );

      final file = await build().chooseFile();

      expect(picker.maxBytes, greaterThan(0));
      expect(file?.parts.single.kind, CsvDataKind.debts);
      expect(file?.parts.single.records.single.cells['amount'], '200.00');
    });

    test('nothing picked is nothing', () async {
      expect(await build().chooseFile(), isNull);
    });

    test('a file that is not an export is refused, before any call', () {
      picker.file = (name: 'a.csv', bytes: utf8.encode('a,b\n1,2\n'));

      expect(build().chooseFile(), throwsA(isA<CsvFileException>()));
      expect(server.requests, isEmpty);
    });
  });

  group('check', () {
    test('sends every 500 rows as a dry run, with no key', () async {
      answer = (options) {
        final rows = bodyOf(options)['rows'] as List<Object?>;
        return jsonBody(200, _result(dryRun: true, imported: rows.length));
      };

      final estimate = await build().check(_transactions(1201));

      final calls = imports();
      expect(calls, hasLength(3));
      for (final call in calls) {
        expect(bodyOf(call)['dry_run'], isTrue);
        expect(bodyOf(call)['dataset'], 'transactions');
        expect(call.headers['Idempotency-Key'], isNull);
      }
      expect(
        [for (final call in calls) (bodyOf(call)['rows'] as List).length],
        [500, 500, 201],
      );
      expect(estimate.imported, 1201);
    });

    test('sends each row with its number and its cells', () async {
      answer = (_) => jsonBody(200, _result(dryRun: true, imported: 1));

      await build().check(_transactions(1, note: '2026-10-24T00:00:00'));

      expect(bodyOf(imports().single)['rows'], [
        {
          'row': 2,
          'date': '2026-10-24',
          'kind': 'expense',
          'amount': '12.50',
          'currency': 'USD',
          'category_key': 'groceries',
          'account_name': 'Travel card',
          // Text that looks like a day at midnight is not cut to the day.
          'note': '2026-10-24T00:00:00',
        },
      ]);
    });

    test('keeps the calls under the size the server takes', () async {
      answer = (options) => jsonBody(
        200,
        _result(
          dryRun: true,
          imported: (bodyOf(options)['rows'] as List).length,
        ),
      );

      await build().check(_transactions(400, note: 'x' * 3000));

      final calls = imports();
      expect(calls.length, greaterThan(1));
      for (final call in calls) {
        expect(utf8.encode(call.data as String).length, lessThan(1024 * 1024));
      }
    });

    test('says why each row would be skipped, by its part', () async {
      answer = (_) => jsonBody(
        200,
        _result(
          dryRun: true,
          imported: 1,
          problems: [
            {'row': 4, 'code': 'required', 'attr': 'date'},
            {'row': 5, 'code': 'unknown_account', 'attr': 'account_name'},
          ],
        ),
      );

      final estimate = await build().check(_transactions(3));

      expect(estimate.imported, 1);
      expect(estimate.problems, const [
        CsvProblem(
          kind: CsvDataKind.transactions,
          row: 4,
          reason: CsvProblemReason.missingDate,
        ),
        CsvProblem(
          kind: CsvDataKind.transactions,
          row: 5,
          reason: CsvProblemReason.unknownAccount,
        ),
      ]);
    });
  });

  group('the calls of a file', () {
    Future<List<List<int>>> rowsOfCalls(CsvFile file) async {
      answer = (options) => jsonBody(
        200,
        _result(
          dryRun: true,
          imported: (bodyOf(options)['rows'] as List).length,
        ),
      );
      await build().check(file);
      return [
        for (final call in imports())
          [
            for (final row in bodyOf(call)['rows'] as List<Object?>)
              (row! as Map<String, Object?>)['row']! as int,
          ],
      ];
    }

    test('never split a day between two calls', () async {
      // Three days of 300 rows each, mixed in the file: a call holds 500.
      final days = [for (var i = 0; i < 900; i++) '2026-10-${10 + i % 3}'];
      final file = CsvFile(name: 't.csv', parts: [_days(days)]);

      final calls = await rowsOfCalls(file);

      expect(calls.map((rows) => rows.length), [300, 300, 300]);
      for (final rows in calls) {
        expect({for (final row in rows) days[row - 2]}, hasLength(1));
      }
    });

    test('fill a call with whole days while they fit', () async {
      final days = [
        for (var i = 0; i < 200; i++) '2026-10-01',
        for (var i = 0; i < 250; i++) '2026-10-02',
        for (var i = 0; i < 100; i++) '2026-10-03',
      ];

      final calls = await rowsOfCalls(
        CsvFile(name: 't.csv', parts: [_days(days)]),
      );

      expect(calls.map((rows) => rows.length), [450, 100]);
    });

    test(
      'cut a day that is more than a call takes, and go on after it',
      () async {
        final days = [
          for (var i = 0; i < 501; i++) '2026-10-01',
          for (var i = 0; i < 3; i++) '2026-10-02',
        ];

        final calls = await rowsOfCalls(
          CsvFile(name: 't.csv', parts: [_days(days)]),
        );

        expect(calls.map((rows) => rows.length), [500, 4]);
      },
    );

    test('send the accounts, then the categories, then the rest', () async {
      CsvFilePart part(CsvDataKind kind, Map<String, Object> cells) {
        return CsvFilePart(
          kind: kind,
          records: [CsvRecord(row: 2, cells: cells)],
        );
      }

      answer = (options) => jsonBody(
        200,
        _result(dataset: bodyOf(options)['dataset'] as String, imported: 1),
      );
      final file = CsvFile(
        name: 'money-scribe-export.zip',
        parts: [
          part(CsvDataKind.accounts, {'name': 'Cash', 'kind': 'cash'}),
          part(CsvDataKind.categories, {'name': 'Pets', 'icon': 'other'}),
          _days(['2026-10-01']),
          part(CsvDataKind.debts, {'person': 'Alex'}),
        ],
      );

      final result = await build().import(file);

      final calls = imports();
      expect(
        [for (final c in calls) bodyOf(c)['dataset']],
        ['accounts', 'categories', 'transactions', 'debts'],
      );
      // Real calls, one key each, and no dry run in between.
      expect([
        for (final c in calls) bodyOf(c)['dry_run'],
      ], everyElement(isFalse));
      expect({
        for (final c in calls) c.headers['Idempotency-Key'],
      }, hasLength(4));
      expect(result.imported, 4);
    });
  });

  group('the estimate of a file that creates its accounts and categories', () {
    CsvFile file() {
      return const CsvFile(
        name: 'money-scribe-export.zip',
        parts: [
          CsvFilePart(
            kind: CsvDataKind.accounts,
            records: [
              CsvRecord(row: 2, cells: {'name': 'Cash', 'kind': 'cash'}),
            ],
          ),
          CsvFilePart(
            kind: CsvDataKind.categories,
            records: [
              CsvRecord(row: 2, cells: {'name': 'Pets', 'icon': 'other'}),
            ],
          ),
          CsvFilePart(
            kind: CsvDataKind.transactions,
            records: [
              CsvRecord(
                row: 2,
                day: '2026-10-01',
                cells: {'account_name': ' cash ', 'category_name': 'PETS'},
              ),
              CsvRecord(
                row: 3,
                day: '2026-10-01',
                cells: {'account_name': 'Old wallet', 'category_key': 'dining'},
              ),
              CsvRecord(
                row: 4,
                day: '2026-10-01',
                cells: {'account_name': 'Cash', 'category_name': 'Gifts'},
              ),
            ],
          ),
        ],
      );
    }

    test('does not count what the file itself creates as unknown', () async {
      answer = (options) {
        final dataset = bodyOf(options)['dataset'];
        return jsonBody(
          200,
          dataset == 'transactions'
              ? _result(
                  dryRun: true,
                  problems: [
                    {
                      'row': 2,
                      'code': 'unknown_account',
                      'attr': 'account_name',
                    },
                    {
                      'row': 3,
                      'code': 'unknown_account',
                      'attr': 'account_name',
                    },
                    {
                      'row': 4,
                      'code': 'unknown_category',
                      'attr': 'category_name',
                    },
                  ],
                )
              : _result(dataset: dataset! as String, dryRun: true, imported: 1),
        );
      };

      final estimate = await build().check(file());

      // Row 2 names an account and a category the file creates; row 3 an
      // account it does not; row 4 a category it does not.
      expect(estimate.imported, 2);
      expect(estimate.problems, const [
        CsvProblem(
          kind: CsvDataKind.transactions,
          row: 3,
          reason: CsvProblemReason.unknownAccount,
        ),
        CsvProblem(
          kind: CsvDataKind.transactions,
          row: 4,
          reason: CsvProblemReason.unknownCategory,
        ),
      ]);
    });

    test('keeps every other problem of a row', () async {
      answer = (options) => jsonBody(
        200,
        bodyOf(options)['dataset'] == 'transactions'
            ? _result(
                dryRun: true,
                problems: [
                  {'row': 2, 'code': 'duplicate', 'attr': null},
                ],
              )
            : _result(dryRun: true, imported: 1),
      );

      final estimate = await build().check(file());

      expect(estimate.problems.single.reason, CsvProblemReason.duplicate);
    });
  });

  group('import', () {
    test('sends each call once, with its own key, and the progress', () async {
      answer = (options) => jsonBody(
        200,
        _result(imported: (bodyOf(options)['rows'] as List).length),
      );
      final progress = <int>[];

      final result = await build().import(
        _transactions(1201),
        onProgress: progress.add,
      );

      final calls = imports();
      expect(
        [for (final c in calls) bodyOf(c)['dry_run']],
        [false, false, false],
      );
      expect(
        [for (final c in calls) c.headers['Idempotency-Key']],
        [
          '"import-key-1-0000000000"',
          '"import-key-2-0000000000"',
          '"import-key-3-0000000000"',
        ],
      );
      expect(progress, [500, 1000, 1201]);
      expect(result, const CsvImportResult(imported: 1201));
    });

    test('a stop goes on where it stopped, with the same key', () async {
      var call = 0;
      answer = (options) {
        call++;
        if (call == 2) throw connectionLost(options);
        return jsonBody(
          200,
          _result(
            imported: (bodyOf(options)['rows'] as List).length - 1,
            problems: [
              {'row': firstRow(options), 'code': 'duplicate', 'attr': null},
            ],
          ),
        );
      };
      final repository = build();
      final file = _transactions(1201);

      await expectLater(
        repository.import(file),
        throwsA(isA<NoConnectionException>()),
      );
      final result = await repository.import(file);

      final sent = [
        for (final c in imports()) (firstRow(c), c.headers['Idempotency-Key']),
      ];
      expect(sent, [
        (2, '"import-key-1-0000000000"'),
        (502, '"import-key-2-0000000000"'),
        (502, '"import-key-2-0000000000"'),
        (1002, '"import-key-3-0000000000"'),
      ]);
      expect(result.imported, 1198);
      expect([for (final p in result.problems) p.row], [2, 502, 1002]);
      expect(result.problems.first.reason, CsvProblemReason.duplicate);
    });

    test('a call the server refused is sent with a new key', () async {
      var call = 0;
      answer = (options) {
        call++;
        if (call == 1) return jsonBody(400, errorBody('request_too_large'));
        return jsonBody(200, _result(imported: 1));
      };
      final repository = build();
      final file = _transactions(1);

      await expectLater(
        repository.import(file),
        throwsA(isA<ServerException>()),
      );
      await repository.import(file);

      expect(
        [for (final c in imports()) c.headers['Idempotency-Key']],
        ['"import-key-1-0000000000"', '"import-key-2-0000000000"'],
      );
    });

    test('a file of several kinds is sent kind after kind', () async {
      answer = (options) => jsonBody(
        200,
        _result(dataset: bodyOf(options)['dataset'] as String, imported: 1),
      );
      const file = CsvFile(
        name: 'money-scribe-export.zip',
        parts: [
          CsvFilePart(
            kind: CsvDataKind.debts,
            records: [
              CsvRecord(row: 2, cells: {'person': 'Alex'}),
            ],
          ),
          CsvFilePart(
            kind: CsvDataKind.salaryMonths,
            records: [
              CsvRecord(row: 2, cells: {'month': '2026-10'}),
            ],
          ),
        ],
      );

      final result = await build().import(file);

      expect(
        [for (final c in imports()) bodyOf(c)['dataset']],
        ['debts', 'salary_months'],
      );
      expect(result.imported, 2);
    });
  });

  test('the reasons of the server are worded, any other is generic', () {
    const reason = RemoteCsvTransferRepository.reasonOf;
    expect(reason('required', 'date'), CsvProblemReason.missingDate);
    expect(reason('required', 'start_date'), CsvProblemReason.missingDate);
    expect(reason('required', 'month'), CsvProblemReason.missingDate);
    expect(reason('required', 'amount'), CsvProblemReason.other);
    expect(reason('invalid_amount', 'amount'), CsvProblemReason.invalidAmount);
    expect(reason('duplicate', null), CsvProblemReason.duplicate);
    expect(
      reason('unknown_category', 'category_key'),
      CsvProblemReason.unknownCategory,
    );
    expect(
      reason('unknown_account', 'account_name'),
      CsvProblemReason.unknownAccount,
    );
    expect(
      reason('transaction_limit_reached', null),
      CsvProblemReason.limitReached,
    );
    expect(
      reason('repayment_limit_reached', 'repayments'),
      CsvProblemReason.limitReached,
    );
    expect(reason('a_code_of_a_newer_server', null), CsvProblemReason.other);
    expect(reason('name_taken', 'name'), CsvProblemReason.nameTaken);
    expect(reason('required', 'icon'), CsvProblemReason.missingIcon);
    expect(reason('required', 'kind'), CsvProblemReason.other);
    expect(
      reason('account_limit_reached', null),
      CsvProblemReason.limitReached,
    );
    expect(
      reason('category_limit_reached', null),
      CsvProblemReason.limitReached,
    );
    // A problem inside a nested cell names its place, counted from 0.
    expect(
      reason('required', 'repayments.0.date'),
      CsvProblemReason.missingDate,
    );
    expect(
      reason('invalid_amount', 'repayments.1.amount'),
      CsvProblemReason.invalidAmount,
    );
    expect(
      reason('invalid_amount', 'fixed_items.1.amount'),
      CsvProblemReason.invalidAmount,
    );
  });
}
