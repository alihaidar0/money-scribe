import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

/// Transactions made of invented figures, until the server exists. It follows
/// the demo panel: no data, one payment or two, slow, failing or offline.
/// What the app adds, changes or deletes is kept in memory for as long as it
/// runs.
class FakeTransactionsRepository implements TransactionsRepository {
  new({required this._demo});

  final DemoController _demo;

  /// What the app changed since it started; it replaces the seed.
  List<Transaction>? _edited;

  var _nextId = 1;

  @override
  Stream<void> get changes => _demo.dataChanges;

  @override
  Future<List<Transaction>> transactions() async {
    await _demo.simulateRequest();
    return List.unmodifiable(_current());
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
    final transaction = Transaction.fromDraft('added-${_nextId++}', draft);
    _edited = [..._current(), transaction];
    return transaction;
  }

  @override
  Future<Transaction> update(String id, TransactionDraft draft) async {
    await _demo.simulateSave();
    final transactions = _current();
    final index = transactions.indexWhere((item) => item.id == id);
    if (index < 0) throw const ServerException();

    final transaction = Transaction.fromDraft(id, draft);
    _edited = [...transactions]..[index] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    await _demo.simulateSave();
    _edited = [
      for (final transaction in _current())
        if (transaction.id != id) transaction,
    ];
  }

  @override
  Future<PaymentMode> paymentMode() async {
    await _demo.simulateRequest();
    return _demo.settings.paymentMode;
  }

  /// The transactions, without waiting for the server.
  List<Transaction> _current() {
    final edited = _edited;
    if (edited != null) return edited;
    if (_demo.settings.scenario == DemoScenario.empty) return const [];
    return TransactionsSeed.transactions();
  }
}
