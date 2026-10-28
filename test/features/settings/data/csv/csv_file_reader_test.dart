import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/data/csv/csv_file_reader.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

const _transactions =
    'date,kind,amount,currency,category_key,category_name,account_name,note\r\n'
    '2026-10-24,expense,12.50,USD,groceries,,Travel card,Weekly shop\r\n'
    "2026-10-25,income,50.00,USD,other,,Travel card,'=Refund\r\n"
    '2026-10-25,expense,8.00,USD,,Pets,Travel card,Food\r\n';

const _debts =
    'direction,person,amount,currency,start_date,due_date,note,repayments\r\n'
    'lent,Alex,200.00,USD,2026-10-01,2026-11-01,Laptop '
    'repair,"[{""date"":""2026-10-20"",""amount"":""50.00""}]"\r\n';

const _accounts = 'name,kind\r\nTravel card,card\r\nCash,cash\r\n';

const _categories = "name,icon\r\nPets,other\r\n'=Odd,gifts\r\n";

Uint8List _bytes(String text, {bool bom = true}) => Uint8List.fromList([
  if (bom) ...[0xEF, 0xBB, 0xBF],
  ...utf8.encode(text),
]);

Uint8List _zip(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(key: name, value: text) in files.entries) {
    archive.add(ArchiveFile.bytes(name, _bytes(text)));
  }
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

Matcher _issue(CsvFileIssue issue) =>
    throwsA(isA<CsvFileException>().having((e) => e.issue, 'issue', issue));

void main() {
  const reader = CsvFileReader();

  group('a CSV file', () {
    test('is known by its header, and its rows keep their numbers', () {
      final file = reader.read(
        'money-scribe-transactions.csv',
        _bytes(_transactions),
      );

      expect(file.name, 'money-scribe-transactions.csv');
      expect(file.rows, 3);
      final part = file.parts.single;
      expect(part.kind, CsvDataKind.transactions);
      expect(part.records.map((r) => r.row), [2, 3, 4]);
      expect(part.records[1].cells['note'], '=Refund');
      expect(part.records[2].cells.containsKey('category_key'), isFalse);
      expect(part.records[2].cells['category_name'], 'Pets');
    });

    test('is read without a byte order mark too', () {
      final file = reader.read('t.csv', _bytes(_transactions, bom: false));

      expect(file.rows, 3);
    });

    test('may use ; between cells', () {
      final text = _transactions.replaceAll(',', ';');

      final file = reader.read('t.csv', _bytes(text));

      expect(file.parts.single.records.first.cells['amount'], '12.50');
    });

    test('may have its columns in another order, and more of them', () {
      const text =
          'note,extra,account_name,category_name,category_key,currency,amount,'
          'kind,date\n'
          'Lunch,x,Wallet,,dining,EUR,9.5,expense,2026-10-02\n';

      final cells = reader
          .read('t.csv', _bytes(text))
          .parts
          .single
          .records
          .single
          .cells;

      expect(cells['amount'], '9.50');
      expect(cells.containsKey('extra'), isFalse);
    });

    test('skips empty rows, and counts them', () {
      const text =
          '$_transactions\r\n,,,,,,,\r\n'
          '2026-10-26,expense,3.00,USD,dining,,Old wallet,\r\n';

      final records = reader.read('t.csv', _bytes(text)).parts.single.records;

      expect(records.map((r) => r.row), [2, 3, 4, 7]);
    });

    test('reads a JSON cell as its list', () {
      final record = reader
          .read('d.csv', _bytes(_debts))
          .parts
          .single
          .records
          .single;

      expect(record.cells['repayments'], [
        {'date': '2026-10-20', 'amount': '50.00'},
      ]);
    });

    test('with other columns is refused', () {
      expect(
        () => reader.read('budget.csv', _bytes('name,total\nfood,10\n')),
        _issue(CsvFileIssue.unknownColumns),
      );
    });

    test('with a column missing is refused', () {
      final text = _transactions.replaceFirst(',note', '');

      expect(
        () => reader.read('t.csv', _bytes(text)),
        _issue(CsvFileIssue.unknownColumns),
      );
    });

    test('with the header only has no rows', () {
      final header = _transactions.split('\r\n').first;

      expect(
        () => reader.read('t.csv', _bytes(header)),
        _issue(CsvFileIssue.noRows),
      );
    });

    test('that is not UTF-8 text cannot be read', () {
      expect(
        () =>
            reader.read('t.csv', Uint8List.fromList([0xFF, 0xFE, 0x00, 0x41])),
        _issue(CsvFileIssue.unreadable),
      );
    });

    test('with a quote never closed cannot be read', () {
      expect(
        () => reader.read('t.csv', _bytes('$_transactions"open')),
        _issue(CsvFileIssue.unreadable),
      );
    });

    test('with more rows than one import takes is refused', () {
      const small = CsvFileReader(maxRows: 2);

      expect(
        () => small.read('t.csv', _bytes(_transactions)),
        throwsA(
          isA<CsvFileException>()
              .having((e) => e.issue, 'issue', CsvFileIssue.tooManyRows)
              .having((e) => e.limit, 'limit', 2),
        ),
      );
    });

    test('larger than the app reads is refused before it is read', () {
      const small = CsvFileReader(maxFileBytes: 10);

      expect(
        () => small.read('t.csv', _bytes(_transactions)),
        _issue(CsvFileIssue.tooLarge),
      );
    });
  });

  group('accounts and categories', () {
    test('an accounts file is known by its two columns', () {
      final file = reader.read('money-scribe-accounts.csv', _bytes(_accounts));

      final part = file.parts.single;
      expect(part.kind, CsvDataKind.accounts);
      expect(part.records.map((r) => r.cells), [
        {'name': 'Travel card', 'kind': 'card'},
        {'name': 'Cash', 'kind': 'cash'},
      ]);
      expect(part.records.first.day, isNull);
    });

    test('a categories file is known by its two columns', () {
      final file = reader.read('c.csv', _bytes(_categories));

      final part = file.parts.single;
      expect(part.kind, CsvDataKind.categories);
      expect(part.records.last.cells, {'name': '=Odd', 'icon': 'gifts'});
    });

    test('a header with the columns of both is refused', () {
      expect(
        () => reader.read('a.csv', _bytes('name,kind,icon\nCash,cash,other\n')),
        _issue(CsvFileIssue.unknownColumns),
      );
    });
  });

  group('the day of a row', () {
    test('is the date of a transaction and the start of a debt', () {
      final transactions = reader.read('t.csv', _bytes(_transactions));
      final debts = reader.read('d.csv', _bytes(_debts));

      expect(transactions.parts.single.records.map((r) => r.day), [
        '2026-10-24',
        '2026-10-25',
        '2026-10-25',
      ]);
      expect(debts.parts.single.records.single.day, '2026-10-01');
    });

    test('is counted as crowded when it has more rows than one call takes', () {
      final rows = [
        for (var i = 0; i < 501; i++)
          '2026-10-24,expense,1.00,USD,groceries,,Cash,Row $i',
        for (var i = 0; i < 3; i++)
          '2026-10-25,expense,1.00,USD,groceries,,Cash,Row $i',
      ].join('\r\n');
      final text = '${_transactions.split('\r\n').first}\r\n$rows\r\n';

      final file = reader.read('t.csv', _bytes(text));

      expect(file.parts.single.crowdedDays, 1);
      expect(file.crowdedDays, 1);
    });

    test('a file with no crowded day has none', () {
      expect(reader.read('t.csv', _bytes(_transactions)).crowdedDays, 0);
    });
  });

  group('a .zip file', () {
    test('of every kind has its parts in the order of an import', () {
      final bytes = _zip({
        'salary_months.csv':
            'month,currency,base_salary,food_per_day,working_days_in_month,'
            'working_hours_in_month,extra_hours,tax_rate,payment_mode,'
            'working_days_first_half,first_pay_day,second_pay_day,fixed_items\n'
            '2026-10,USD,3000.00,5.00,22,176,7.50,15.00,one_payment,,20,5,[]\n',
        'debts.csv': _debts,
        'transactions.csv': _transactions,
        'categories.csv': _categories,
        'accounts.csv': _accounts,
      });

      final file = reader.read('money-scribe-export.zip', bytes);

      expect(file.parts.map((p) => p.kind), CsvDataKind.values);
      expect(file.rows, 2 + 2 + 3 + 1 + 1);
    });

    test('has a part per file it knows, in the order of the kinds', () {
      final bytes = _zip({
        'money-scribe-export/debts.csv': _debts,
        'transactions.csv': _transactions,
        'notes.txt': 'not an export',
      });

      final file = reader.read('money-scribe-export.zip', bytes);

      expect(file.parts.map((p) => p.kind), [
        CsvDataKind.transactions,
        CsvDataKind.debts,
      ]);
      expect(file.rows, 4);
    });

    test('with none of the files of an export is refused', () {
      expect(
        () => reader.read('a.zip', _zip({'notes.csv': 'a,b\n1,2\n'})),
        _issue(CsvFileIssue.unknownColumns),
      );
    });

    test('whose file has the header of another kind is refused', () {
      expect(
        () => reader.read('a.zip', _zip({'debts.csv': _transactions})),
        _issue(CsvFileIssue.unknownColumns),
      );
    });

    test('larger than the app reads once unzipped is refused', () {
      const small = CsvFileReader(maxUnzippedBytes: 100);

      expect(
        () => small.read('a.zip', _zip({'transactions.csv': _transactions})),
        _issue(CsvFileIssue.tooLarge),
      );
    });

    test('that is broken cannot be read', () {
      final bytes = Uint8List.fromList([0x50, 0x4b, 0x03, 0x04, 1, 2, 3]);

      expect(
        () => reader.read('a.zip', bytes),
        _issue(CsvFileIssue.unreadable),
      );
    });
  });
}
