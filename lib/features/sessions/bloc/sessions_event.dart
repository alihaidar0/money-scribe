part of 'sessions_bloc.dart';

sealed class SessionsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The screen opened: load the sessions that are active.
final class SessionsStarted extends SessionsEvent {
  const new();
}

/// The user pressed Try again on the tab that is shown.
final class SessionsRetried extends SessionsEvent {
  const new();
}

/// The sessions may have changed: load them again without the loading state.
final class SessionsRefreshed extends SessionsEvent {
  const new();
}

/// The user chose a tab.
final class SessionsTabSelected extends SessionsEvent {
  const new(this.tab);

  final SessionsTab tab;

  @override
  List<Object?> get props => [tab];
}

/// The user asked for the next page of the sessions that ended.
final class PreviousSessionsMoreRequested extends SessionsEvent {
  const new();
}

/// The user confirmed ending the session [id].
final class SessionEndConfirmed extends SessionsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
