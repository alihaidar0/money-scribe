import 'package:money_scribe/features/transactions/domain/account.dart';

/// Where the accounts come from: the server. Can throw a `DataException` when
/// the server cannot be reached or fails.
abstract interface class AccountsRepository {
  /// Every account, in the order the person arranged them.
  Future<List<Account>> accounts();
}
