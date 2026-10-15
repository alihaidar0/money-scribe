import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

/// The Sign in screen: sends the email and password, and counts down while
/// sign-in is locked after too many wrong attempts.
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  new({required this._repository, required this._ticker})
    : super(_initialState(_repository)) {
    on<SignInStarted>(_onStarted, transformer: droppable());
    // A second press while the first is being sent is ignored.
    on<SignInSubmitted>(_onSubmitted, transformer: droppable());
    on<_SignInLockTicked>(_onLockTicked, transformer: sequential());
  }

  final AuthRepository _repository;
  final Ticker _ticker;
  StreamSubscription<int>? _lockTimer;

  static SignInState _initialState(AuthRepository repository) {
    final locked = repository.signInLockRemaining;
    if (locked == null) return const SignInState();
    return SignInState(
      status: SignInStatus.locked,
      lockSecondsLeft: _wholeSeconds(locked),
    );
  }

  static int _wholeSeconds(Duration duration) {
    return (duration.inMilliseconds / 1000).ceil();
  }

  void _onStarted(SignInStarted event, Emitter<SignInState> emit) {
    if (state.status == SignInStatus.locked) {
      _startLockTimer(state.lockSecondsLeft);
    }
  }

  Future<void> _onSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInState(status: SignInStatus.submitting));
    try {
      await _repository.signIn(email: event.email, password: event.password);
      emit(const SignInState(status: SignInStatus.success));
    } on WrongCredentialsException {
      emit(const SignInState(status: SignInStatus.wrongCredentials));
    } on TooManyAttemptsException catch (error) {
      final seconds = _wholeSeconds(error.retryAfter);
      emit(SignInState(status: SignInStatus.locked, lockSecondsLeft: seconds));
      _startLockTimer(seconds);
    } on NoConnectionException {
      emit(const SignInState(status: SignInStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const SignInState(status: SignInStatus.failure));
    }
  }

  void _onLockTicked(_SignInLockTicked event, Emitter<SignInState> emit) {
    if (state.status != SignInStatus.locked) return;
    emit(
      event.secondsLeft > 0
          ? SignInState(
              status: SignInStatus.locked,
              lockSecondsLeft: event.secondsLeft,
            )
          : const SignInState(),
    );
  }

  void _startLockTimer(int seconds) {
    unawaited(_lockTimer?.cancel());
    _lockTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_SignInLockTicked(left)));
  }

  @override
  Future<void> close() async {
    await _lockTimer?.cancel();
    await super.close();
  }
}
