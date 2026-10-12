part of 'accounts_bloc.dart';

sealed class AccountsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The Accounts screen opened: load the accounts.
final class AccountsStarted extends AccountsEvent {
  const new();
}

/// The user pressed Try again.
final class AccountsRetried extends AccountsEvent {
  const new();
}

/// The user added an account in the sheet.
final class AccountAdded extends AccountsEvent {
  const new(this.draft);

  final AccountDraft draft;

  @override
  List<Object> get props => [draft];
}

/// The user changed the account [id] in the sheet.
final class AccountChanged extends AccountsEvent {
  const new(this.id, this.draft);

  final String id;
  final AccountDraft draft;

  @override
  List<Object> get props => [id, draft];
}

/// The user deleted the account [id].
final class AccountDeleted extends AccountsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
