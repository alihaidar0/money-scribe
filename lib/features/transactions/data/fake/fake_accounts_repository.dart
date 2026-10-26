import 'dart:async';

import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';

/// The accounts of the fake server: a card and cash. It follows the demo
/// panel's slow, failing and offline answers. What the app adds, changes or
/// deletes is kept in memory for as long as it runs. It keeps the rules of the
/// server: a name is used once (in any case), there are at most [maxAccounts],
/// a change or a delete needs the version it was made from, and with
/// `transactions` an account that has transactions cannot be deleted.
class FakeAccountsRepository implements AccountsRepository {
  new({required this._demo, this._transactions});

  /// The most accounts a person has.
  static const maxAccounts = 20;

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
    final accounts = _current();
    if (accounts.length >= maxAccounts) {
      throw const AccountRefusedException(AccountRefusal.limitReached);
    }
    _checkName(accounts, draft.name);
    final account = Account(
      id: 'added-${_nextId++}',
      name: draft.name,
      kind: draft.kind,
    );
    _edited = [...accounts, account];
    _changes.add(null);
    return account;
  }

  @override
  Future<Account> update(
    String id,
    AccountDraft draft, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final accounts = _current();
    final index = accounts.indexWhere((account) => account.id == id);
    if (index < 0 || accounts[index].version != version) {
      throw const StaleRecordException();
    }
    _checkName(accounts, draft.name, except: id);

    final old = accounts[index];
    final unchanged = old.name == draft.name && old.kind == draft.kind;
    final account = Account(
      id: id,
      name: draft.name,
      kind: draft.kind,
      version: unchanged ? old.version : old.version + 1,
    );
    _edited = [...accounts]..[index] = account;
    _changes.add(null);
    return account;
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    await _demo.simulateSave();
    final accounts = _current();
    final index = accounts.indexWhere((account) => account.id == id);
    if (index < 0) return;
    if (accounts[index].version != version) throw const StaleRecordException();
    if (_transactions?.hasTransactionsInAccount(id) ?? false) {
      throw const AccountInUseException();
    }
    _edited = [
      for (final account in accounts)
        if (account.id != id) account,
    ];
    _changes.add(null);
  }

  void _checkName(List<Account> accounts, String name, {String? except}) {
    final wanted = name.trim().toLowerCase();
    final taken = accounts.any(
      (account) => account.id != except && account.name.toLowerCase() == wanted,
    );
    if (taken) throw const AccountRefusedException(AccountRefusal.nameTaken);
  }

  List<Account> _current() => _edited ?? TransactionsSeed.accounts;
}
