part of 'security_activity_bloc.dart';

sealed class SecurityActivityEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The screen opened: load the first page.
final class SecurityActivityStarted extends SecurityActivityEvent {
  const new();
}

/// The user pressed Try again.
final class SecurityActivityRetried extends SecurityActivityEvent {
  const new();
}

/// The user asked for the next page.
final class SecurityActivityMoreRequested extends SecurityActivityEvent {
  const new();
}
