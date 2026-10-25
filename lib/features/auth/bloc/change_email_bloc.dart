import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'change_email_event.dart';
part 'change_email_state.dart';

/// The first step of changing the email: the new address and the current
/// password. The server emails a code to the new address; the address of the
/// account changes only when that code is confirmed on the next screen. The
/// app checks nothing about the address itself: the server says what is wrong
/// with it. Every wait comes from the server.
class ChangeEmailBloc extends Bloc<ChangeEmailEvent, ChangeEmailState> {
  new({required this._repository, required this._ticker})
    : super(const ChangeEmailState()) {
    on<ChangeEmailEdited>(_onEdited, transformer: sequential());
    // A second press while the first is being sent is ignored.
    on<ChangeEmailSubmitted>(_onSubmitted, transformer: droppable());
    on<_ChangeEmailWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  final AuthRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _waitTimer;

  void _onEdited(ChangeEmailEdited event, Emitter<ChangeEmailState> emit) {
    emit(
      ChangeEmailState(
        // Typing after a refusal starts a new try; a wait the server asked for
        // goes on.
        status: state.status == ChangeEmailStatus.waiting
            ? ChangeEmailStatus.waiting
            : ChangeEmailStatus.editing,
        email: event.email,
        password: event.password,
        waitSecondsLeft: state.waitSecondsLeft,
      ),
    );
  }

  Future<void> _onSubmitted(
    ChangeEmailSubmitted event,
    Emitter<ChangeEmailState> emit,
  ) async {
    // A wait from the server is not over yet.
    if (!state.canSend || state.status == ChangeEmailStatus.waiting) return;
    emit(state.copyWith(status: ChangeEmailStatus.sending));
    try {
      await _repository.requestEmailChange(
        email: state.email,
        password: state.password,
      );
      emit(state.copyWith(status: ChangeEmailStatus.sent));
    } on WrongCredentialsException {
      emit(state.copyWith(status: ChangeEmailStatus.wrongPassword));
    } on EmailChangeRejectedException catch (error) {
      emit(
        state.copyWith(status: ChangeEmailStatus.rejected, issue: error.issue),
      );
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        state.copyWith(
          status: ChangeEmailStatus.waiting,
          waitSecondsLeft: seconds,
        ),
      );
      unawaited(_waitTimer?.cancel());
      _waitTimer = _ticker
          .countdown(seconds)
          .listen((left) => add(_ChangeEmailWaitTicked(left)));
    } on ServiceUnavailableException {
      emit(state.copyWith(status: ChangeEmailStatus.unavailable));
    } on NoConnectionException {
      emit(state.copyWith(status: ChangeEmailStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: ChangeEmailStatus.failure));
    }
  }

  void _onWaitTicked(
    _ChangeEmailWaitTicked event,
    Emitter<ChangeEmailState> emit,
  ) {
    if (state.status != ChangeEmailStatus.waiting) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(waitSecondsLeft: event.secondsLeft)
          : state.copyWith(
              status: ChangeEmailStatus.editing,
              waitSecondsLeft: 0,
            ),
    );
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
