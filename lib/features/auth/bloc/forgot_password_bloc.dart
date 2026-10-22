import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

/// The Forgot password screen: asks the server to send a code to the email.
/// The answer is the same for every address, so the next screen always
/// follows. The only refusal is a wait, which the button counts down.
class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  new({required this._repository, required this._ticker})
    : super(const ForgotPasswordState()) {
    // A second press while the first is being sent is ignored.
    on<ForgotPasswordSubmitted>(_onSubmitted, transformer: droppable());
    on<_ForgotPasswordWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  final AuthRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _waitTimer;

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    // A wait from the server is not over yet.
    if (state.status == ForgotPasswordStatus.waiting) return;

    emit(const ForgotPasswordState(status: ForgotPasswordStatus.submitting));
    try {
      await _repository.requestPasswordReset(event.email);
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.success));
    } on RateLimitedException catch (error) {
      // The code was asked for a moment ago, or too often this hour: the
      // button counts down until the server accepts it again.
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        ForgotPasswordState(
          status: ForgotPasswordStatus.waiting,
          waitSecondsLeft: seconds,
        ),
      );
      _startWaitTimer(seconds);
    } on ServiceUnavailableException {
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.unavailable));
    } on NoConnectionException {
      emit(
        const ForgotPasswordState(status: ForgotPasswordStatus.noConnection),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const ForgotPasswordState(status: ForgotPasswordStatus.failure));
    }
  }

  void _onWaitTicked(
    _ForgotPasswordWaitTicked event,
    Emitter<ForgotPasswordState> emit,
  ) {
    if (state.status != ForgotPasswordStatus.waiting) return;
    emit(
      event.secondsLeft > 0
          ? ForgotPasswordState(
              status: ForgotPasswordStatus.waiting,
              waitSecondsLeft: event.secondsLeft,
            )
          : const ForgotPasswordState(),
    );
  }

  void _startWaitTimer(int seconds) {
    unawaited(_waitTimer?.cancel());
    _waitTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_ForgotPasswordWaitTicked(left)));
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
