import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

/// The Sign in screen: sends the email and password, and counts down while
/// the server asks to wait (sign-in locked after too many wrong attempts, or
/// too many requests). It never checks the password against a policy. A phone
/// that has a fingerprint key offers to sign in with it first.
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  new({
    required this._repository,
    required this._deviceKeys,
    required this._ticker,
  }) : super(_initialState(_repository)) {
    on<SignInStarted>(_onStarted, transformer: droppable());
    // A second press while the fingerprint is being checked is ignored.
    on<SignInFingerprintRequested>(
      _onFingerprintRequested,
      transformer: droppable(),
    );
    on<SignInOtherAccountChosen>(
      _onOtherAccountChosen,
      transformer: sequential(),
    );
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
  final DeviceKeyRepository _deviceKeys;
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

  Future<void> _onStarted(
    SignInStarted event,
    Emitter<SignInState> emit,
  ) async {
    if (state.status == SignInStatus.locked) {
      _startLockTimer(state.lockSecondsLeft);
    }
    emit(state.copyWith(fingerprintAccount: await _fingerprintAccount()));
  }

  /// The account of the key of this phone. A phone that cannot be asked has
  /// none, so the password form shows.
  Future<FingerprintAccount?> _fingerprintAccount() async {
    try {
      return await _deviceKeys.signInAccount();
    } on Object {
      return null;
    }
  }

  void _onOtherAccountChosen(
    SignInOtherAccountChosen event,
    Emitter<SignInState> emit,
  ) {
    emit(_to(SignInStatus.idle, usePassword: true));
  }

  Future<void> _onFingerprintRequested(
    SignInFingerprintRequested event,
    Emitter<SignInState> emit,
  ) async {
    if (state.fingerprintAccount == null) return;

    emit(_to(SignInStatus.fingerprintSubmitting, viaFingerprint: true));
    try {
      await _deviceKeys.signIn(prompt: event.prompt);
      emit(_to(SignInStatus.success));
    } on FingerprintCancelledException {
      // Not said: the person can touch the sensor again.
      emit(_to(SignInStatus.idle));
    } on FingerprintUnavailableException {
      emit(_to(SignInStatus.fingerprintUnavailable, viaFingerprint: true));
    } on FingerprintKeyInvalidatedException {
      // The key is gone from the phone, so nothing is offered any more.
      emit(
        _to(
          SignInStatus.fingerprintKeyChanged,
          usePassword: true,
          clearAccount: true,
        ),
      );
    } on FingerprintRefusedException {
      emit(_to(SignInStatus.fingerprintRefused, usePassword: true));
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(_to(SignInStatus.locked, lockSecondsLeft: seconds));
      _startLockTimer(seconds);
    } on ServiceUnavailableException {
      emit(_to(SignInStatus.unavailable, viaFingerprint: true));
    } on NoConnectionException {
      emit(_to(SignInStatus.noConnection, viaFingerprint: true));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(_to(SignInStatus.failure, viaFingerprint: true));
    }
  }

  /// The state with [status], keeping the account of the key and the choice of
  /// the password form, and forgetting everything else.
  SignInState _to(
    SignInStatus status, {
    int lockSecondsLeft = 0,
    bool? usePassword,
    bool viaFingerprint = false,
    bool clearAccount = false,
  }) {
    return SignInState(
      status: status,
      lockSecondsLeft: lockSecondsLeft,
      fingerprintAccount: clearAccount ? null : state.fingerprintAccount,
      usePassword: usePassword ?? state.usePassword,
      viaFingerprint: viaFingerprint,
    );
  }

  Future<void> _onSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(_to(SignInStatus.submitting));
    try {
      await _repository.signIn(
        email: event.email,
        password: event.password,
        challengeToken: event.challengeToken,
      );
      emit(_to(SignInStatus.success));
    } on ChallengeRequiredException {
      emit(_to(SignInStatus.challengeRequired));
    } on ChallengeRejectedException {
      emit(_to(SignInStatus.challengeRejected));
    } on EmailNotRegisteredException {
      emit(_to(SignInStatus.emailNotRegistered));
    } on WrongPasswordException {
      emit(_to(SignInStatus.wrongPassword));
    } on WrongCredentialsException {
      emit(_to(SignInStatus.wrongCredentials));
    } on EmailNotVerifiedException {
      // The right password, but the address still has to be verified.
      emit(_to(SignInStatus.emailNotVerified));
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(_to(SignInStatus.locked, lockSecondsLeft: seconds));
      _startLockTimer(seconds);
    } on ServiceUnavailableException {
      emit(_to(SignInStatus.unavailable));
    } on NoConnectionException {
      emit(_to(SignInStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(_to(SignInStatus.failure));
    }
  }

  void _onChallengeDismissed(
    SignInChallengeDismissed event,
    Emitter<SignInState> emit,
  ) {
    // Nothing is sent: the person decides whether to press Sign in again.
    if (state.status == SignInStatus.challengeRequired ||
        state.status == SignInStatus.challengeRejected) {
      emit(_to(SignInStatus.idle));
    }
  }

  void _onEmailEdited(SignInEmailEdited event, Emitter<SignInState> emit) {
    // Another address is another account: every message about the old one is
    // stale, the password message too.
    if (_isRefusal(state.status)) emit(_to(SignInStatus.idle));
  }

  void _onPasswordEdited(
    SignInPasswordEdited event,
    Emitter<SignInState> emit,
  ) {
    if (state.status == SignInStatus.wrongPassword ||
        state.status == SignInStatus.wrongCredentials) {
      emit(_to(SignInStatus.idle));
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
          ? _to(SignInStatus.locked, lockSecondsLeft: event.secondsLeft)
          : _to(SignInStatus.idle),
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
