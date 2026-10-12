part of 'accounts_bloc.dart';

enum AccountsStatus {
  /// The accounts are being loaded.
  loading,

  /// The accounts are shown.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class AccountsState extends Equatable {
  const new({
    this.status = AccountsStatus.loading,
    this.accounts = const [],
    this.failedAction,
    this.deleteBlocked = false,
  });

  final AccountsStatus status;

  /// Every account, in the order the person arranged them.
  final List<Account> accounts;

  /// The last add, change or delete that the server did not accept, so the
  /// screen can offer to try it again. `null` once something else was done.
  final AccountsEvent? failedAction;

  /// Whether the last delete was refused because the account has
  /// transactions. It stays until something else is done.
  final bool deleteBlocked;

  AccountsState copyWith({
    AccountsStatus? status,
    List<Account>? accounts,
    AccountsEvent? failedAction,
    bool? deleteBlocked,
    bool clearFailedAction = false,
  }) {
    return AccountsState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
      deleteBlocked: deleteBlocked ?? this.deleteBlocked,
    );
  }

  @override
  List<Object?> get props => [status, accounts, failedAction, deleteBlocked];
}
