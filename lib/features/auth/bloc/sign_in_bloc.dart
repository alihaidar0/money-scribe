import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

/// The Sign in screen: sends the email and password, and counts down while
/// the server asks to wait (sign-in locked after too many wrong attempts, or
/// too many requests). It never checks the password against a policy.
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  new({required this._repository, required this._ticker})
    : super(_initialState(_repository)) {
    on<SignInStarted>(_onStarted, transformer: droppable());
    // A second press while the first is being sent is ignored.
    on<SignInSubmitted>(_onSubmitted, transformer: droppable());
    on<SignInChallengeDismissed>(
      _onChallengeDismissed,
      transformer: sequential(),
    );
    on<SignInEmailEdited>(_onEmailEdited, transformer: sequential());
    on<SignInPasswordEdited>(_onPasswordEdited, transformer: sequential());
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
      lockSecondsLeft: locked.ceilSeconds,
    );
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
      await _repository.signIn(
        email: event.email,
        password: event.password,
        challengeToken: event.challengeToken,
      );
      emit(const SignInState(status: SignInStatus.success));
    } on ChallengeRequiredException {
      emit(const SignInState(status: SignInStatus.challengeRequired));
    } on ChallengeRejectedException {
      emit(const SignInState(status: SignInStatus.challengeRejected));
    } on EmailNotRegisteredException {
      emit(const SignInState(status: SignInStatus.emailNotRegistered));
    } on WrongPasswordException {
      emit(const SignInState(status: SignInStatus.wrongPassword));
    } on WrongCredentialsException {
      emit(const SignInState(status: SignInStatus.wrongCredentials));
    } on EmailNotVerifiedException {
      // The right password, but the address still has to be verified.
      emit(const SignInState(status: SignInStatus.emailNotVerified));
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(SignInState(status: SignInStatus.locked, lockSecondsLeft: seconds));
      _startLockTimer(seconds);
    } on ServiceUnavailableException {
      emit(const SignInState(status: SignInStatus.unavailable));
    } on NoConnectionException {
      emit(const SignInState(status: SignInStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const SignInState(status: SignInStatus.failure));
    }
  }

  void _onChallengeDismissed(
    SignInChallengeDismissed event,
    Emitter<SignInState> emit,
  ) {
    // Nothing is sent: the person decides whether to press Sign in again.
    if (state.status == SignInStatus.challengeRequired ||
        state.status == SignInStatus.challengeRejected) {
      emit(const SignInState());
    }
  }

  void _onEmailEdited(SignInEmailEdited event, Emitter<SignInState> emit) {
    // Another address is another account: every message about the old one is
    // stale, the password message too.
    if (_isRefusal(state.status)) emit(const SignInState());
  }

  void _onPasswordEdited(
    SignInPasswordEdited event,
    Emitter<SignInState> emit,
  ) {
    if (state.status == SignInStatus.wrongPassword ||
        state.status == SignInStatus.wrongCredentials) {
      emit(const SignInState());
    }
  }

  static bool _isRefusal(SignInStatus status) =>
      status == SignInStatus.emailNotRegistered ||
      status == SignInStatus.wrongPassword ||
      status == SignInStatus.wrongCredentials;

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
