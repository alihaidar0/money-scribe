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
    this.staleAction,
    this.refusal,
    this.deleteBlocked = false,
  });

  final AccountsStatus status;

  /// Every account, in the order the person arranged them.
  final List<Account> accounts;

  /// The last add, change or delete that the server did not accept, so the
  /// screen can offer to try it again. `null` once something else was done.
  final AccountsEvent? failedAction;

  /// The last change or delete that was refused because the account was
  /// changed on another device; the list was loaded again. `null` once
  /// something else was done.
  final AccountsEvent? staleAction;

  /// Why the last add or change was refused, if the person can act on it. It
  /// stays until something else is done.
  final AccountRefusal? refusal;

  /// Whether the last delete was refused because the account has
  /// transactions. It stays until something else is done.
  final bool deleteBlocked;

  AccountsState copyWith({
    AccountsStatus? status,
    List<Account>? accounts,
    AccountsEvent? failedAction,
    AccountsEvent? staleAction,
    AccountRefusal? refusal,
    bool? deleteBlocked,
    bool clearFailedAction = false,
    bool clearStaleAction = false,
    bool clearRefusal = false,
  }) {
    return AccountsState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
      staleAction: clearStaleAction ? null : staleAction ?? this.staleAction,
      refusal: clearRefusal ? null : refusal ?? this.refusal,
      deleteBlocked: deleteBlocked ?? this.deleteBlocked,
    );
  }

  @override
  List<Object?> get props => [
    status,
    accounts,
    failedAction,
    staleAction,
    refusal,
    deleteBlocked,
  ];
}
