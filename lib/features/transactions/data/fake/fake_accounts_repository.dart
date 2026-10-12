import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';

/// The accounts of the fake server: a card and cash. It follows the demo
/// panel's slow, failing and offline answers.
class FakeAccountsRepository implements AccountsRepository {
  new({required this._demo});

  final DemoController _demo;

  @override
  Future<List<Account>> accounts() async {
    await _demo.simulateRequest();
    return TransactionsSeed.accounts;
  }
}
