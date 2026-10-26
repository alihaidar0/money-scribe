import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

part 'revoke_others_event.dart';
part 'revoke_others_state.dart';

/// The dialog that signs the other devices out: the password is checked by
/// the server, a wrong one is said under the field, and too many wrong ones
/// lock the button with the countdown the server gave.
class RevokeOthersBloc extends Bloc<RevokeOthersEvent, RevokeOthersState> {
  new({required this._repository, required this._ticker})
    : super(const RevokeOthersState()) {
    on<RevokeOthersPasswordEdited>(_onEdited, transformer: sequential());
    // A second press while the first is being sent is ignored.
    on<RevokeOthersSubmitted>(_onSubmitted, transformer: droppable());
    on<_RevokeOthersWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  final SessionsRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _waitTimer;

  void _onEdited(
    RevokeOthersPasswordEdited event,
    Emitter<RevokeOthersState> emit,
  ) {
    emit(
      RevokeOthersState(
        // Typing after a refusal starts a new try; a wait the server asked for
        // goes on.
        status: state.status == RevokeOthersStatus.waiting
            ? RevokeOthersStatus.waiting
            : RevokeOthersStatus.editing,
        password: event.password,
        waitSecondsLeft: state.waitSecondsLeft,
      ),
    );
  }

  Future<void> _onSubmitted(
    RevokeOthersSubmitted event,
    Emitter<RevokeOthersState> emit,
  ) async {
    if (state.password.isEmpty || state.status == RevokeOthersStatus.waiting) {
      return;
    }
    emit(state.copyWith(status: RevokeOthersStatus.revoking));
    try {
      final result = await _repository.endOthers(password: state.password);
      emit(state.copyWith(status: RevokeOthersStatus.done, result: result));
    } on SessionRefusedException {
      emit(state.copyWith(status: RevokeOthersStatus.wrongPassword));
    } on TooManyRequestsException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        state.copyWith(
          status: RevokeOthersStatus.waiting,
          waitSecondsLeft: seconds,
        ),
      );
      _startWaitTimer(seconds);
    } on ServiceUnavailableException {
      emit(state.copyWith(status: RevokeOthersStatus.unavailable));
    } on NoConnectionException {
      emit(state.copyWith(status: RevokeOthersStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: RevokeOthersStatus.failure));
    }
  }

  void _onWaitTicked(
    _RevokeOthersWaitTicked event,
    Emitter<RevokeOthersState> emit,
  ) {
    if (state.status != RevokeOthersStatus.waiting) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(waitSecondsLeft: event.secondsLeft)
          : state.copyWith(
              status: RevokeOthersStatus.editing,
              waitSecondsLeft: 0,
            ),
    );
  }

  void _startWaitTimer(int seconds) {
    unawaited(_waitTimer?.cancel());
    _waitTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_RevokeOthersWaitTicked(left)));
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
