import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

/// The Where you are signed in screen: the sessions that are active, those
/// that ended (read the first time their tab is opened, a page at a time),
/// and ending the session of another device.
class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  new({required this._repository}) : super(const SessionsState()) {
    _changes = _repository.changes.listen(
      (_) => add(const SessionsRefreshed()),
    );
    on<SessionsStarted>(_onStarted, transformer: droppable());
    on<SessionsRetried>(_onRetried, transformer: droppable());
    on<SessionsRefreshed>(_onRefreshed, transformer: restartable());
    on<SessionsTabSelected>(_onTabSelected, transformer: sequential());
    on<PreviousSessionsMoreRequested>(_onMore, transformer: droppable());
    on<SessionEndConfirmed>(_onEnd, transformer: sequential());
  }

  final SessionsRepository _repository;

  late final StreamSubscription<void> _changes;

  Future<void> _onStarted(SessionsStarted event, Emitter<SessionsState> emit) {
    return _loadActive(emit, showLoading: true);
  }

  Future<void> _onRetried(SessionsRetried event, Emitter<SessionsState> emit) {
    return state.tab == SessionsTab.active
        ? _loadActive(emit, showLoading: true)
        : _loadPrevious(emit, showLoading: true);
  }

  Future<void> _onRefreshed(
    SessionsRefreshed event,
    Emitter<SessionsState> emit,
  ) async {
    await _loadActive(emit, showLoading: false);
    if (state.previousStatus != PreviousStatus.idle) {
      await _loadPrevious(emit, showLoading: false);
    }
  }

  Future<void> _onTabSelected(
    SessionsTabSelected event,
    Emitter<SessionsState> emit,
  ) async {
    emit(state.copyWith(tab: event.tab));
    if (event.tab == SessionsTab.previous &&
        state.previousStatus == PreviousStatus.idle) {
      await _loadPrevious(emit, showLoading: true);
    }
  }

  Future<void> _onMore(
    PreviousSessionsMoreRequested event,
    Emitter<SessionsState> emit,
  ) async {
    final cursor = state.previousNext;
    if (cursor == null) return;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await _repository.ended(cursor: cursor);
      emit(
        state.copyWith(
          previous: [...state.previous, ...page.items],
          previousNext: page.nextCursor,
          clearPreviousNext: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } on Exception catch (error, stackTrace) {
      if (error is! NoConnectionException) addError(error, stackTrace);
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  Future<void> _onEnd(
    SessionEndConfirmed event,
    Emitter<SessionsState> emit,
  ) async {
    emit(state.copyWith(endingId: event.id, clearFailedAction: true));
    try {
      await _repository.end(event.id);
    } on Exception catch (error, stackTrace) {
      if (error is! NoConnectionException) addError(error, stackTrace);
      emit(state.copyWith(clearEndingId: true, failedAction: event));
      return;
    }
    emit(state.copyWith(clearEndingId: true, endedCount: state.endedCount + 1));
    await _onRefreshed(const SessionsRefreshed(), emit);
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  Future<void> _loadActive(
    Emitter<SessionsState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) emit(state.copyWith(status: SessionsStatus.loading));
    try {
      final sessions = await _repository.active();
      emit(state.copyWith(status: SessionsStatus.ready, active: sessions));
    } on NoConnectionException {
      emit(state.copyWith(status: SessionsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(status: SessionsStatus.failure));
    }
  }

  Future<void> _loadPrevious(
    Emitter<SessionsState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(state.copyWith(previousStatus: PreviousStatus.loading));
    }
    try {
      final page = await _repository.ended();
      emit(
        state.copyWith(
          previousStatus: PreviousStatus.ready,
          previous: page.items,
          previousNext: page.nextCursor,
          clearPreviousNext: page.nextCursor == null,
          loadMoreFailed: false,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(previousStatus: PreviousStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(previousStatus: PreviousStatus.failure));
    }
  }
}
