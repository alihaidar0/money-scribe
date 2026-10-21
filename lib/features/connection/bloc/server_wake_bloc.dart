import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/connection/domain/server_activity.dart';

part 'server_wake_event.dart';
part 'server_wake_state.dart';

/// Whether to tell the person that the server is starting: a request has been
/// waiting for it for a few seconds.
class ServerWakeBloc extends Bloc<ServerWakeEvent, ServerWakeState> {
  new({required this._activity})
    : super(ServerWakeState(isWaking: _activity.isSlow)) {
    // Listening once is enough.
    on<ServerWakeStarted>(_onStarted, transformer: droppable());
  }

  final ServerActivity _activity;

  Future<void> _onStarted(
    ServerWakeStarted event,
    Emitter<ServerWakeState> emit,
  ) {
    return emit.onEach<bool>(
      _activity.slowChanges,
      onData: (isSlow) => emit(ServerWakeState(isWaking: isSlow)),
      onError: addError,
    );
  }
}
