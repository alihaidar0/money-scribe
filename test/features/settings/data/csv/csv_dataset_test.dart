import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/data/csv/csv_dataset.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

void main() {
  group('padDecimals', () {
    test('adds the zeros a spreadsheet dropped', () {
      expect(CsvDataset.padDecimals('12.5', 2), '12.50');
      expect(CsvDataset.padDecimals('12', 2), '12.00');
      expect(CsvDataset.padDecimals('12.', 2), '12.00');
      expect(CsvDataset.padDecimals('-3.1', 2), '-3.10');
      expect(CsvDataset.padDecimals('7', 0), '7');
      expect(CsvDataset.padDecimals('7.5', 3), '7.500');
    });

    test('never rounds, and leaves what is not a plain number', () {
      expect(CsvDataset.padDecimals('12.345', 2), '12.345');
      expect(CsvDataset.padDecimals('12,50', 2), '12,50');
      expect(CsvDataset.padDecimals('1e3', 2), '1e3');
      expect(CsvDataset.padDecimals(' 12', 2), ' 12');
    });
  });

  group('withoutFormulaGuard', () {
    test('removes the one quote the export put in front of a formula', () {
      expect(CsvDataset.withoutFormulaGuard("'=Refund"), '=Refund');
      expect(CsvDataset.withoutFormulaGuard("'+1"), '+1');
      expect(CsvDataset.withoutFormulaGuard("'-5"), '-5');
      expect(CsvDataset.withoutFormulaGuard("'@home"), '@home');
      expect(CsvDataset.withoutFormulaGuard("'\tx"), '\tx');
      expect(CsvDataset.withoutFormulaGuard("''=x"), "'=x");
      expect(CsvDataset.withoutFormulaGuard("'''-x"), "''-x");
    });

    test('leaves any other text as it is', () {
      expect(CsvDataset.withoutFormulaGuard("'quoted'"), "'quoted'");
      expect(CsvDataset.withoutFormulaGuard("'"), "'");
      expect(CsvDataset.withoutFormulaGuard('=x'), '=x');
      expect(CsvDataset.withoutFormulaGuard('Weekly shop'), 'Weekly shop');
    });
  });

  group('cellsOf', () {
    test('sends the columns of the kind, and leaves empty cells out', () {
      final cells = CsvDataset.transactions.cellsOf({
        'date': '2026-10-24',
        'kind': 'expense',
        'amount': '12.5',
        'currency': 'USD',
        'category_key': 'groceries',
        'category_name': '',
        'account_name': 'Travel card',
        'note': "'=Refund",
        'comment': 'not a column',
      });

      expect(cells, {
        'date': '2026-10-24',
        'kind': 'expense',
        'amount': '12.50',
        'currency': 'USD',
        'category_key': 'groceries',
        'account_name': 'Travel card',
        'note': '=Refund',
      });
    });

    test('an amount of an unknown currency is sent as it is', () {
      final cells = CsvDataset.transactions.cellsOf({
        'amount': '12.5',
        'currency': 'XYZ',
      });

      expect(cells['amount'], '12.5');
    });

    test('a JSON cell is sent as its list, and as text when it is not one', () {
      final debt = CsvDataset.debts.cellsOf({
        'repayments': '[{"date":"2026-10-20","amount":"50.00"}]',
        'note': '[not json',
      });
      final broken = CsvDataset.debts.cellsOf({'repayments': '[1,'});

      expect(debt['repayments'], [
        {'date': '2026-10-20', 'amount': '50.00'},
      ]);
      expect(debt['note'], '[not json');
      expect(broken['repayments'], '[1,');
    });

    test('hours and percent get two decimals', () {
      final cells = CsvDataset.salaryMonths.cellsOf({
        'extra_hours': '7.5',
        'tax_rate': '15',
        'working_days_in_month': '22',
        'fixed_items': '[]',
      });

      expect(cells['extra_hours'], '7.50');
      expect(cells['tax_rate'], '15.00');
      expect(cells['working_days_in_month'], '22');
      expect(cells['fixed_items'], <Object?>[]);
    });
  });

  group('accounts and categories', () {
    test('send their two columns, and leave a formula guard out of a name', () {
      expect(
        CsvDataset.accounts.cellsOf({
          'name': "'=Cash",
          'kind': 'cash',
          'x': 'y',
        }),
        {'name': '=Cash', 'kind': 'cash'},
      );
      expect(
        CsvDataset.categories.cellsOf({
          'name': 'Pets',
          'icon': 'other',
          'kind': 'both',
        }),
        {'name': 'Pets', 'icon': 'other'},
      );
    });

    test('a category with no icon sends none, so the server says so', () {
      expect(CsvDataset.categories.cellsOf({'name': 'Pets', 'icon': ''}), {
        'name': 'Pets',
      });
    });
  });

  group('forHeader', () {
    test('knows each kind by its columns', () {
      expect(CsvDataset.forHeader(['name', 'kind']), CsvDataset.accounts);
      expect(CsvDataset.forHeader(['name', 'icon']), CsvDataset.categories);
      expect(CsvDataset.forHeader(CsvDataset.debts.columns), CsvDataset.debts);
    });

    test('takes the only kind whose columns the header has, with more', () {
      expect(
        CsvDataset.forHeader([...CsvDataset.transactions.columns, 'extra']),
        CsvDataset.transactions,
      );
    });

    test('refuses a header that could be two kinds', () {
      expect(CsvDataset.forHeader(['name', 'icon', 'kind']), isNull);
    });

    test('is null for a header that is no kind', () {
      expect(CsvDataset.forHeader(['name', 'total']), isNull);
    });
  });

  group('dayOf', () {
    test('is the date of a transaction and the start of a debt', () {
      expect(
        CsvDataset.transactions.dayOf({'date': ' 2026-10-24 '}),
        '2026-10-24',
      );
      expect(
        CsvDataset.debts.dayOf({'start_date': '2026-10-01'}),
        '2026-10-01',
      );
      expect(CsvDataset.transactions.dayOf({}), '');
    });

    test('is nothing for a kind with no day', () {
      expect(CsvDataset.accounts.dayOf({'name': 'Cash'}), isNull);
      expect(CsvDataset.salaryMonths.dayOf({'month': '2026-10'}), isNull);
    });
  });

  test('every kind has its dataset, in the order of a file', () {
    expect(
      CsvDataset.values.map((dataset) => dataset.kind),
      CsvDataKind.values,
    );
    expect(
      CsvDataset.of(CsvDataKind.salaryMonths).fileName,
      'salary_months.csv',
    );
  });
}
