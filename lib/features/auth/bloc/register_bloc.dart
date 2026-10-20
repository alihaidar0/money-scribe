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

part 'register_event.dart';
part 'register_state.dart';

/// The Create account screen: sends the new account and shows what the server
/// refused. The only rule it applies itself is that the two password fields
/// match; the server owns every other password rule.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  new({required this._repository, required this._ticker})
    : super(const RegisterState()) {
    // A second press while the first is being sent is ignored.
    on<RegisterSubmitted>(_onSubmitted, transformer: droppable());
    on<_RegisterWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  final AuthRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _waitTimer;

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    // A wait from the server is not over yet.
    if (state.status == RegisterStatus.waiting) return;

    // The same text typed twice is the only check made on the device.
    if (event.password != event.confirmation) {
      emit(
        const RegisterState(
          status: RegisterStatus.rejected,
          passwordsDoNotMatch: true,
        ),
      );
      return;
    }

    emit(const RegisterState(status: RegisterStatus.submitting));
    try {
      await _repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(const RegisterState(status: RegisterStatus.success));
    } on RegistrationRejectedException catch (error) {
      emit(
        RegisterState(
          status: RegisterStatus.rejected,
          passwordProblem: error.password,
          emailInvalid: error.emailInvalid,
          nameInvalid: error.nameInvalid,
        ),
      );
    } on RateLimitedException catch (error) {
      // The same address was registered a moment ago: the button counts down
      // until the server accepts it again.
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        RegisterState(status: RegisterStatus.waiting, waitSecondsLeft: seconds),
      );
      _startWaitTimer(seconds);
    } on ServiceUnavailableException {
      emit(const RegisterState(status: RegisterStatus.unavailable));
    } on NoConnectionException {
      emit(const RegisterState(status: RegisterStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const RegisterState(status: RegisterStatus.failure));
    }
  }

  void _onWaitTicked(_RegisterWaitTicked event, Emitter<RegisterState> emit) {
    if (state.status != RegisterStatus.waiting) return;
    emit(
      event.secondsLeft > 0
          ? RegisterState(
              status: RegisterStatus.waiting,
              waitSecondsLeft: event.secondsLeft,
            )
          : const RegisterState(),
    );
  }

  void _startWaitTimer(int seconds) {
    unawaited(_waitTimer?.cancel());
    _waitTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_RegisterWaitTicked(left)));
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
