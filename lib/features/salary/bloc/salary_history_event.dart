part of 'salary_history_bloc.dart';

sealed class SalaryHistoryEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The history opened: load the saved months.
final class SalaryHistoryStarted extends SalaryHistoryEvent {
  const new();
}

/// The user came back from a month that may have been changed: load the saved
/// months again, without showing the loading state.
final class SalaryHistoryRefreshed extends SalaryHistoryEvent {
  const new({this.done});

  /// Completed when the load is done, to end a pull-to-refresh spinner.
  final Completer<void>? done;
}

/// The user pressed Try again.
final class SalaryHistoryRetried extends SalaryHistoryEvent {
  const new();
}

/// The saved months may have changed: load them again.
final class SalaryHistoryDataChanged extends SalaryHistoryEvent {
  const new();
}
