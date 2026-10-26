import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transactions_page.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

/// Transactions made of invented figures, until the server exists. It follows
/// the demo panel: no data, one payment or two, slow, failing or offline.
/// What the app adds, changes or deletes is kept in memory for as long as it
/// runs.
///
/// It keeps the rules of the server: the lists are cut into pages with a
/// cursor, newest first (a day, then the one added last); the filters and the
/// note search are done here; a day's total is counted for each currency; a
/// change or a delete needs the version it was made from; and a person has at
/// most [maxTransactions].
class FakeTransactionsRepository implements TransactionsRepository {
  new({required this._demo, this.maxTransactions = defaultMaxTransactions});

  /// The most transactions a person has on the server.
  static const defaultMaxTransactions = 100000;

  /// The first and the last day the server keeps.
  static final firstDay = DateTime(2000);
  static final lastDay = DateTime(2099, 12, 31);

  final DemoController _demo;

  /// The most transactions this fake holds (the server's is
  /// [defaultMaxTransactions]; a test sets a small one).
  final int maxTransactions;

  /// What the app changed since it started; it replaces the seed. In the order
  /// the transactions were added.
  List<Transaction>? _edited;

  var _nextId = 1;

  @override
  Stream<void> get changes => _demo.dataChanges;

  @override
  Future<TransactionsPage> transactions(
    TransactionFilter filter, {
    String? cursor,
    int pageSize = TransactionsRepository.defaultPageSize,
  }) async {
    await _demo.simulateRequest();
    final matching = _newestFirst(filter);
    final start = _offsetOf(cursor);
    final end = start + pageSize;
    return TransactionsPage(
      items: List.unmodifiable(matching.skip(start).take(pageSize)),
      nextCursor: end < matching.length ? '$end' : null,
    );
  }

  @override
  Future<DayTotalsPage> dayTotals(
    TransactionFilter filter, {
    String? cursor,
    int pageSize = TransactionsRepository.defaultPageSize,
  }) async {
    await _demo.simulateRequest();
    // The search is not a filter of the totals.
    final withoutSearch = TransactionFilter(
      categoryIds: filter.categoryIds,
      accountIds: filter.accountIds,
      from: filter.from,
      to: filter.to,
    );
    final byDay = <DateTime, Map<String, Money>>{};
    for (final transaction in _newestFirst(withoutSearch)) {
      final day = byDay.putIfAbsent(transaction.date, () => {});
      final currency = transaction.amount.currency;
      day[currency.code] =
          (day[currency.code] ?? Money.zero(currency)) +
          transaction.signedAmount;
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final start = _offsetOf(cursor);
    final end = start + pageSize;
    return DayTotalsPage(
      days: [
        for (final date in days.skip(start).take(pageSize))
          DayTotal(
            date: date,
            totals: [
              for (final code in byDay[date]!.keys.toList()..sort())
                byDay[date]![code]!,
            ],
          ),
      ],
      nextCursor: end < days.length ? '$end' : null,
    );
  }

  @override
  Future<Transaction?> transaction(String id) async {
    await _demo.simulateRequest();
    for (final transaction in _current()) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  @override
  Future<Transaction> add(TransactionDraft draft) async {
    await _demo.simulateSave();
    final transactions = _current();
    if (transactions.length >= maxTransactions) {
      throw const TransactionRefusedException(TransactionRefusal.limitReached);
    }
    _checkDate(draft.date);
    final transaction = Transaction.fromDraft('added-${_nextId++}', draft);
    _edited = [...transactions, transaction];
    return transaction;
  }

  @override
  Future<Transaction> update(
    String id,
    TransactionDraft draft, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final transactions = _current();
    final index = transactions.indexWhere((item) => item.id == id);
    if (index < 0 || transactions[index].version != version) {
      throw const StaleRecordException();
    }
    _checkDate(draft.date);

    final transaction = Transaction.fromDraft(
      id,
      draft,
      version: transactions[index].draft == draft ? version : version + 1,
    );
    _edited = [...transactions]..[index] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    await _demo.simulateSave();
    final transactions = _current();
    final found = transactions.where((transaction) => transaction.id == id);
    if (found.isEmpty) return;
    if (found.first.version != version) throw const StaleRecordException();
    _edited = [
      for (final transaction in transactions)
        if (transaction.id != id) transaction,
    ];
  }

  @override
  Future<PaymentMode> paymentMode() async {
    await _demo.simulateRequest();
    return _demo.settings.paymentMode;
  }

  /// Whether any transaction is in the account [accountId]. The fake accounts
  /// ask it before deleting one.
  bool hasTransactionsInAccount(String accountId) {
    return _current().any((transaction) => transaction.accountId == accountId);
  }

  /// Moves the transactions of the category [from] to the category [to], as
  /// the server does when a category is deleted: only the category and the
  /// version of each change.
  void moveCategory({required String from, required String to}) {
    _edited = [
      for (final transaction in _current())
        if (transaction.categoryId == from)
          Transaction(
            id: transaction.id,
            amount: transaction.amount,
            kind: transaction.kind,
            date: transaction.date,
            categoryId: to,
            accountId: transaction.accountId,
            note: transaction.note,
            version: transaction.version + 1,
          )
        else
          transaction,
    ];
  }

  /// The transactions that pass [filter], the newest first: by day, then the
  /// one added last.
  List<Transaction> _newestFirst(TransactionFilter filter) {
    final all = _current();
    final order = {for (var i = 0; i < all.length; i++) all[i].id: i};
    return all.where(filter.matches).toList()..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : order[b.id]!.compareTo(order[a.id]!);
    });
  }

  void _checkDate(DateTime date) {
    if (date.isBefore(firstDay) || date.isAfter(lastDay)) {
      throw const TransactionRefusedException(
        TransactionRefusal.dateOutOfRange,
      );
    }
  }

  int _offsetOf(String? cursor) => int.tryParse(cursor ?? '') ?? 0;

  /// The transactions, without waiting for the server.
  List<Transaction> _current() {
    final edited = _edited;
    if (edited != null) return edited;
    if (_demo.settings.scenario == DemoScenario.empty) return const [];
    return TransactionsSeed.transactions();
  }
}
