import 'dart:async';

import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';

/// The accounts of the fake server: a card and cash. It follows the demo
/// panel's slow, failing and offline answers. What the app adds, changes or
/// deletes is kept in memory for as long as it runs. With `transactions`, an
/// account that has transactions cannot be deleted, as on the server.
class FakeAccountsRepository implements AccountsRepository {
  new({required this._demo, this._transactions});

  final DemoController _demo;
  final FakeTransactionsRepository? _transactions;
  final _changes = StreamController<void>.broadcast();

  List<Account>? _edited;
  var _nextId = 1;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Account>> accounts() async {
    await _demo.simulateRequest();
    return List.unmodifiable(_current());
  }

  @override
  Future<Account> add(AccountDraft draft) async {
    await _demo.simulateSave();
    final account = Account(
      id: 'added-${_nextId++}',
      name: draft.name,
      kind: draft.kind,
    );
    _edited = [..._current(), account];
    _changes.add(null);
    return account;
  }

  @override
  Future<Account> update(String id, AccountDraft draft) async {
    await _demo.simulateSave();
    final accounts = _current();
    final index = accounts.indexWhere((account) => account.id == id);
    if (index < 0) throw const ServerException();

    final account = Account(id: id, name: draft.name, kind: draft.kind);
    _edited = [...accounts]..[index] = account;
    _changes.add(null);
    return account;
  }

  @override
  Future<void> delete(String id) async {
    await _demo.simulateSave();
    if (_transactions?.hasTransactionsInAccount(id) ?? false) {
      throw const AccountInUseException();
    }
    _edited = [
      for (final account in _current())
        if (account.id != id) account,
    ];
    _changes.add(null);
  }

  List<Account> _current() => _edited ?? TransactionsSeed.accounts;
}
