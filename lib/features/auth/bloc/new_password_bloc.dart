import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

part 'new_password_event.dart';
part 'new_password_state.dart';

/// The New password screen: checks that the two fields are the same text as
/// they are typed, and saves the password. The app applies no other rule: the
/// server owns the password policy and says what is wrong with a password.
class NewPasswordBloc extends Bloc<NewPasswordEvent, NewPasswordState> {
  new({required this._repository, required this._ticker})
    : super(const NewPasswordState()) {
    on<NewPasswordChanged>(_onChanged, transformer: sequential());
    // A second press while the first is being saved is ignored.
    on<NewPasswordSubmitted>(_onSubmitted, transformer: droppable());
    on<_NewPasswordWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  final AuthRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _waitTimer;

  void _onChanged(NewPasswordChanged event, Emitter<NewPasswordState> emit) {
    emit(
      NewPasswordState(
        // Typing again clears what the server refused; a wait it asked for
        // goes on.
        status: state.status == NewPasswordStatus.waiting
            ? NewPasswordStatus.waiting
            : NewPasswordStatus.editing,
        matches:
            event.password.isNotEmpty && event.password == event.confirmation,
        mismatch:
            event.confirmation.isNotEmpty &&
            event.confirmation != event.password,
        waitSecondsLeft: state.waitSecondsLeft,
      ),
    );
  }

  Future<void> _onSubmitted(
    NewPasswordSubmitted event,
    Emitter<NewPasswordState> emit,
  ) async {
    // A wait from the server is not over yet.
    if (!state.isValid || state.status == NewPasswordStatus.waiting) return;
    emit(state.copyWith(status: NewPasswordStatus.saving));
    try {
      await _repository.resetPassword(event.password);
      emit(state.copyWith(status: NewPasswordStatus.saved));
    } on PasswordRejectedException catch (error) {
      // The reset is still open: another password may be tried.
      emit(
        state.copyWith(
          status: NewPasswordStatus.rejected,
          passwordProblem: error.problem,
        ),
      );
    } on ResetTokenInvalidException {
      emit(state.copyWith(status: NewPasswordStatus.expired));
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        state.copyWith(
          status: NewPasswordStatus.waiting,
          waitSecondsLeft: seconds,
        ),
      );
      _startWaitTimer(seconds);
    } on ServiceUnavailableException {
      emit(state.copyWith(status: NewPasswordStatus.unavailable));
    } on NoConnectionException {
      emit(state.copyWith(status: NewPasswordStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: NewPasswordStatus.failure));
    }
  }

  void _onWaitTicked(
    _NewPasswordWaitTicked event,
    Emitter<NewPasswordState> emit,
  ) {
    if (state.status != NewPasswordStatus.waiting) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(waitSecondsLeft: event.secondsLeft)
          : state.copyWith(
              status: NewPasswordStatus.editing,
              waitSecondsLeft: 0,
            ),
    );
  }

  void _startWaitTimer(int seconds) {
    unawaited(_waitTimer?.cancel());
    _waitTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_NewPasswordWaitTicked(left)));
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
