part of 'transactions_bloc.dart';

sealed class TransactionsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: load the transactions.
final class TransactionsStarted extends TransactionsEvent {
  const new();
}

/// The user pressed Try again.
final class TransactionsRetried extends TransactionsEvent {
  const new();
}

/// The transactions may have changed: load them again.
final class TransactionsDataChanged extends TransactionsEvent {
  const new();
}

/// The user came back from a form that may have changed a transaction: load
/// them again without showing the loading state.
final class TransactionsRefreshed extends TransactionsEvent {
  const new();
}

/// The user typed in the search field.
final class TransactionsSearched extends TransactionsEvent {
  const new(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

/// The user applied the Filters sheet: its choices of [filter] (the search
/// words are kept) and the [scope] it shows.
final class TransactionFiltersApplied extends TransactionsEvent {
  const new(this.filter, this.scope);

  final TransactionFilter filter;
  final PeriodScope scope;

  @override
  List<Object> get props => [filter, scope];
}

/// The user cleared the search and the filters.
final class TransactionFiltersCleared extends TransactionsEvent {
  const new();
}

/// The user chose the whole month or one part of it.
final class TransactionsScopeSelected extends TransactionsEvent {
  const new(this.scope);

  final PeriodScope scope;

  @override
  List<Object> get props => [scope];
}

/// The user chose a transaction in the list of a wide window, to see it in the
/// detail pane.
final class TransactionSelected extends TransactionsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

/// The user confirmed deleting the transaction [id] from the detail pane.
final class TransactionDeleteConfirmed extends TransactionsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
