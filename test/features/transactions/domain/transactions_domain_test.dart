import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transaction_groups.dart';

Money rub(int rubles, [int kopecks = 0]) =>
    Money(rubles * 100 + kopecks, Currency.rub);

Transaction transaction({
  String id = 't',
  int rubles = 100,
  TransactionKind kind = TransactionKind.expense,
  DateTime? date,
  String category = 'groceries',
  String account = 'card',
  String note = '',
}) {
  return Transaction(
    id: id,
    amount: rub(rubles),
    kind: kind,
    date: date ?? DateTime(2026, 10, 5),
    categoryId: category,
    accountId: account,
    note: note,
  );
}

void main() {
  group('TransactionDraft.tryCreate', () {
    TransactionDraft? create({
      String amount = '1284.50',
      String? category = 'groceries',
      String? account = 'card',
      String note = 'Weekly shopping',
      DateTime? date,
    }) {
      return TransactionDraft.tryCreate(
        amount: amount,
        currency: Currency.rub,
        kind: TransactionKind.expense,
        date: date ?? DateTime(2026, 10, 5, 14, 30),
        categoryId: category,
        accountId: account,
        note: note,
      );
    }

    test('makes a draft of what was typed, on a calendar day', () {
      final draft = create();

      expect(draft?.amount, rub(1284, 50));
      expect(draft?.date, DateTime(2026, 10, 5));
      expect(draft?.note, 'Weekly shopping');
    });

    test('trims the note', () {
      expect(create(note: '  Taxi ')?.note, 'Taxi');
    });

    test('needs a positive amount', () {
      expect(create(amount: ''), isNull);
      expect(create(amount: 'abc'), isNull);
      expect(create(amount: '0'), isNull);
      expect(create(amount: '-3'), isNull);
    });

    test('needs a category and an account', () {
      expect(create(category: null), isNull);
      expect(create(account: null), isNull);
    });

    test('has a note of at most a hundred characters', () {
      expect(create(note: 'a' * 100), isNotNull);
      expect(create(note: 'a' * 101), isNull);
    });
  });

  group('Transaction', () {
    test('an expense has a negative signed amount', () {
      expect(transaction().signedAmount, rub(-100));
    });

    test('an income keeps its sign', () {
      expect(transaction(kind: TransactionKind.income).signedAmount, rub(100));
    });

    test('its draft is what it is made of', () {
      final item = transaction(note: 'x');

      expect(Transaction.fromDraft(item.id, item.draft), item);
    });
  });

  group('TransactionCategory.isFor', () {
    test('an expense category is for expenses only', () {
      const category = TransactionCategory(
        id: 'a',
        name: 'A',
        icon: CategoryIcon.other,
      );

      expect(category.isFor(TransactionKind.expense), isTrue);
      expect(category.isFor(TransactionKind.income), isFalse);
    });

    test('an income category is for income only', () {
      const category = TransactionCategory(
        id: 'a',
        name: 'A',
        icon: CategoryIcon.other,
        kind: CategoryKind.income,
      );

      expect(category.isFor(TransactionKind.expense), isFalse);
      expect(category.isFor(TransactionKind.income), isTrue);
    });

    test('a category for both is for both', () {
      const category = TransactionCategory(
        id: 'a',
        name: 'A',
        icon: CategoryIcon.other,
        kind: CategoryKind.both,
      );

      expect(category.isFor(TransactionKind.expense), isTrue);
      expect(category.isFor(TransactionKind.income), isTrue);
    });
  });

  group('TransactionFilter', () {
    bool matches(TransactionFilter filter, Transaction transaction) {
      return filter.matches(transaction);
    }

    test('an empty filter matches everything and is not active', () {
      const filter = TransactionFilter();

      expect(filter.isActive, isFalse);
      expect(matches(filter, transaction()), isTrue);
    });

    test('searches the note only, in any case', () {
      final item = transaction(note: 'Weekly shopping');

      expect(matches(const TransactionFilter(query: 'weekly'), item), isTrue);
      expect(matches(const TransactionFilter(query: 'SHOP'), item), isTrue);
      expect(matches(const TransactionFilter(query: 'xyz'), item), isFalse);
      expect(matches(const TransactionFilter(query: '   '), item), isTrue);
      // Neither the category nor the account is searched.
      expect(
        matches(const TransactionFilter(query: 'groceries'), item),
        isFalse,
      );
      expect(matches(const TransactionFilter(query: 'card'), item), isFalse);
    });

    test('a search of one letter is no search, as for the server', () {
      final item = transaction(note: 'Weekly shopping');
      const one = TransactionFilter(query: ' w ');

      expect(one.searchTerm, isNull);
      expect(one.isSearching, isFalse);
      expect(matches(one, transaction(note: 'xyz')), isTrue);
      expect(matches(one, item), isTrue);
    });

    test('the words sent are trimmed and cut to what the server takes', () {
      expect(const TransactionFilter(query: '  tax  ').searchTerm, 'tax');
      expect(TransactionFilter(query: 'x' * 150).searchTerm, 'x' * 100);
      expect(const TransactionFilter(query: 'tax').isSearching, isTrue);
    });

    test('filters by category and by account', () {
      final item = transaction();

      expect(
        matches(const TransactionFilter(categoryIds: {'groceries'}), item),
        isTrue,
      );
      expect(
        matches(const TransactionFilter(categoryIds: {'dining'}), item),
        isFalse,
      );
      expect(
        matches(const TransactionFilter(accountIds: {'cash'}), item),
        isFalse,
      );
    });

    test('filters by day, both ends included', () {
      final item = transaction(date: DateTime(2026, 10, 5));

      expect(
        matches(TransactionFilter(from: DateTime(2026, 10, 5)), item),
        isTrue,
      );
      expect(
        matches(TransactionFilter(from: DateTime(2026, 10, 6)), item),
        isFalse,
      );
      expect(
        matches(TransactionFilter(to: DateTime(2026, 10, 5)), item),
        isTrue,
      );
      expect(
        matches(TransactionFilter(to: DateTime(2026, 10, 4)), item),
        isFalse,
      );
    });

    test('tells the search from the choices of the sheet', () {
      expect(const TransactionFilter(query: 'a').hasQuery, isTrue);
      expect(const TransactionFilter(query: 'a').hasSheetFilters, isFalse);
      expect(
        const TransactionFilter(accountIds: {'cash'}).hasSheetFilters,
        isTrue,
      );
    });

    test('takes the sheet choices of another filter and keeps its search', () {
      const mine = TransactionFilter(query: 'tax');
      const other = TransactionFilter(query: 'ignored', accountIds: {'cash'});

      final merged = mine.withSheetFiltersOf(other);

      expect(merged.query, 'tax');
      expect(merged.accountIds, {'cash'});
    });
  });

  group('TransactionGroups.byDay', () {
    List<Transaction> newestFirst() =>
        TransactionsSeed.transactions().reversed.toList();

    test('lists the newest day first, with the totals it is given', () {
      final days = TransactionGroups.byDay(
        newestFirst(),
        totals: {
          DateTime(2026, 10, 19): [rub(-640)],
          DateTime(2026, 10, 17): [rub(-220)],
          DateTime(2026, 10, 5): [const Money(-128450, Currency.rub)],
          DateTime(2026, 10): [rub(5000)],
        },
      );

      expect(days.map((day) => day.date), [
        DateTime(2026, 10, 19),
        DateTime(2026, 10, 17),
        DateTime(2026, 10, 5),
        DateTime(2026, 10),
      ]);
      expect(days.map((day) => day.totals), [
        [rub(-640)],
        [rub(-220)],
        [const Money(-128450, Currency.rub)],
        [rub(5000)],
      ]);
    });

    test('keeps the order of the server within a day', () {
      final days = TransactionGroups.byDay([
        transaction(id: 'second', rubles: 20),
        transaction(id: 'first', rubles: 10),
      ]);

      expect(days.single.transactions.map((item) => item.id), [
        'second',
        'first',
      ]);
    });

    test('has no total for a day it was not given one for', () {
      final days = TransactionGroups.byDay(
        [transaction(), transaction(date: DateTime(2026, 10, 6))],
        totals: {
          DateTime(2026, 10, 6): [rub(-100)],
        },
      );

      expect(days.map((day) => day.totals), [
        [rub(-100)],
        null,
      ]);
    });

    test('has no totals at all while none are given (a search is on)', () {
      final days = TransactionGroups.byDay([transaction()]);

      expect(days.single.totals, isNull);
    });

    test('keeps a total for each currency', () {
      final days = TransactionGroups.byDay(
        [transaction()],
        totals: {
          DateTime(2026, 10, 5): [rub(-100), const Money(4250, Currency.usd)],
        },
      );

      expect(days.single.totals, [rub(-100), const Money(4250, Currency.usd)]);
    });

    test('is empty for no transactions', () {
      expect(TransactionGroups.byDay(const []), isEmpty);
    });
  });

  group('TransactionGroups.byPeriod', () {
    // The first payment on the 20th, the second on the 5th of the next month.
    final cycle = PayCycle.twoPayments(firstPayDay: 20, secondPayDay: 5);

    test('cuts at the pay days, the newest part first', () {
      final periods = TransactionGroups.byPeriod(
        TransactionsSeed.transactions().reversed.toList(),
        cycle: cycle,
      );

      // The 5th to the 19th of October is the second part of September, and
      // the 1st of October the first part of September.
      expect(periods.map((period) => period.part), [
        PeriodScope.secondPart,
        PeriodScope.firstPart,
      ]);
      expect(periods.first.days.map((day) => day.date.day), [19, 17, 5]);
      expect(periods.last.days.map((day) => day.date.day), [1]);
      expect(periods.first.month, const YearMonth(2026, 9));
      expect(periods.last.month, const YearMonth(2026, 9));
    });

    test('gives each part the days it covers', () {
      final periods = TransactionGroups.byPeriod([
        transaction(date: DateTime(2026, 10, 25)),
        transaction(date: DateTime(2026, 11, 13)),
      ], cycle: cycle);

      expect(periods.map((period) => period.range), [
        PayPeriod(start: DateTime(2026, 11, 5), end: DateTime(2026, 11, 19)),
        PayPeriod(start: DateTime(2026, 10, 20), end: DateTime(2026, 11, 4)),
      ]);
      expect(periods.map((period) => period.month), [
        const YearMonth(2026, 10),
        const YearMonth(2026, 10),
      ]);
    });

    test('keeps the parts of different months apart', () {
      final periods = TransactionGroups.byPeriod([
        transaction(date: DateTime(2026, 9, 20)),
        transaction(date: DateTime(2026, 10, 20)),
      ], cycle: cycle);

      expect(periods.map((period) => period.month), [
        const YearMonth(2026, 10),
        const YearMonth(2026, 9),
      ]);
    });
  });
}
