part of 'account_bloc.dart';

enum AccountStatus {
  /// The name and the email are being loaded.
  loading,

  /// The account is shown.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

/// What the last sign out or delete did.
enum AccountAction {
  /// Nothing was asked, or the last answer was forgotten.
  none,

  /// The person is being signed out.
  signingOut,

  /// Signing out failed.
  signOutFailed,

  /// The account is being deleted.
  deleting,

  /// The password typed to delete the account is wrong.
  wrongPassword,

  /// The server could not be reached, or failed, so the account is still there.
  deleteFailed,

  /// The server asked to wait before the password is sent again (too many
  /// wrong passwords): see [AccountState.deleteWaitSecondsLeft].
  deleteWaiting,

  /// The server is busy: try again shortly.
  deleteUnavailable,

  /// The account was deleted.
  deleted,
}

final class AccountState extends Equatable {
  const new({
    this.status = AccountStatus.loading,
    this.profile,
    this.action = AccountAction.none,
    this.deleteWaitSecondsLeft = 0,
  });

  final AccountStatus status;
  final AccountProfile? profile;
  final AccountAction action;

  /// Seconds until the password can be sent again, while [action] is
  /// `deleteWaiting`.
  final int deleteWaitSecondsLeft;

  /// Whether a sign out or a delete is under way.
  bool get isBusy =>
      action == AccountAction.signingOut || action == AccountAction.deleting;

  AccountState copyWith({
    AccountStatus? status,
    AccountProfile? profile,
    AccountAction? action,
    int? deleteWaitSecondsLeft,
  }) {
    return AccountState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      action: action ?? this.action,
      deleteWaitSecondsLeft:
          deleteWaitSecondsLeft ?? this.deleteWaitSecondsLeft,
    );
  }

  @override
  List<Object?> get props => [status, profile, action, deleteWaitSecondsLeft];
}
