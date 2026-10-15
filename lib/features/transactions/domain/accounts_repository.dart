import 'package:money_scribe/features/transactions/domain/account.dart';

/// Where the accounts come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class AccountsRepository {
  /// Emits when the accounts changed, so a screen showing them loads them
  /// again.
  Stream<void> get changes;

  /// Every account, in the order the person arranged them.
  Future<List<Account>> accounts();

  /// Adds the account [draft] and returns it with its id.
  Future<Account> add(AccountDraft draft);

  /// Replaces what the account [id] is made of and returns it.
  Future<Account> update(String id, AccountDraft draft);

  /// Deletes the account [id]. Throws [AccountInUseException] while it has
  /// transactions. Deleting one that is gone does nothing.
  Future<void> delete(String id);
}
