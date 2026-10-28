part of 'debts_bloc.dart';

sealed class DebtsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: load the debts.
final class DebtsStarted extends DebtsEvent {
  const new();
}

/// The user pressed Try again.
final class DebtsRetried extends DebtsEvent {
  const new();
}

/// The debts may have changed: load them again.
final class DebtsDataChanged extends DebtsEvent {
  const new();
}

/// The user came back from a screen that may have changed a debt: load them
/// again without showing the loading state.
final class DebtsRefreshed extends DebtsEvent {
  const new({this.done});

  /// Completed when the load is done, to end a pull-to-refresh spinner.
  final Completer<void>? done;
}

/// The user chose which debts to list.
final class DebtsFilterSelected extends DebtsEvent {
  const new(this.filter);

  final DebtsFilter filter;

  @override
  List<Object> get props => [filter];
}

/// The user chose a debt in the list of a wide window, to see it in the detail
/// pane.
final class DebtSelected extends DebtsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

/// The user confirmed deleting the debt [id] from the detail pane.
final class DebtDeleteConfirmed extends DebtsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
