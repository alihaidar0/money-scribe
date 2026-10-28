import 'package:money_scribe/features/transactions/domain/account.dart';

/// Where the accounts come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class AccountsRepository {
  /// Emits when the accounts changed, so a screen showing them loads them
  /// again.
  Stream<void> get changes;

  /// Every account, in the order the person arranged them.
  Future<List<Account>> accounts();

  /// Adds the account [draft] and returns it with its id. Throws
  /// [AccountRefusedException] when the name is taken or the person has the
  /// most accounts allowed.
  Future<Account> add(AccountDraft draft);

  /// Replaces what the account [id] is made of and returns it. [version] is
  /// the version the change was made from: an account that changed since
  /// throws a `StaleRecordException` and nothing is changed. Throws
  /// [AccountRefusedException] when the name is taken.
  Future<Account> update(String id, AccountDraft draft, {required int version});

  /// Deletes the account [id] at [version]. Throws [AccountInUseException]
  /// while it has transactions and a `StaleRecordException` when it changed
  /// since. Deleting one that is gone does nothing.
  Future<void> delete(String id, {required int version});
}
