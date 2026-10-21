part of 'server_wake_bloc.dart';

sealed class ServerWakeEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The app opened: start following how fast the server answers.
final class ServerWakeStarted extends ServerWakeEvent {
  const new();
}
