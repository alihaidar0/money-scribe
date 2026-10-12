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
  const new();
}

/// The user chose which debts to list.
final class DebtsFilterSelected extends DebtsEvent {
  const new(this.filter);

  final DebtsFilter filter;

  @override
  List<Object> get props => [filter];
}
