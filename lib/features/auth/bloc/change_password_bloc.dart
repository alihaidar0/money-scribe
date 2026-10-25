import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

/// The Change password screen: the current password, and a new one typed
/// twice. The app applies no password rule of its own: the server owns the
/// policy and says what is wrong with the new password, and for how long to
/// wait after too many wrong current passwords.
///
/// The server removes every fingerprint sign-in key when the password changes.
/// When it was on for this phone, the saved state says so, so the screen can
/// offer to turn it on again with the password just typed.
class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  new({
    required this._repository,
    required this._deviceKeys,
    required this._ticker,
  }) : super(const ChangePasswordState()) {
    on<ChangePasswordEdited>(_onEdited, transformer: sequential());
    // A second press while the first is being saved is ignored.
    on<ChangePasswordSubmitted>(_onSubmitted, transformer: droppable());
    on<_ChangePasswordWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  final AuthRepository _repository;
  final DeviceKeyRepository _deviceKeys;
  final Ticker _ticker;
  StreamSubscription<int>? _waitTimer;

  void _onEdited(
    ChangePasswordEdited event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(
      ChangePasswordState(
        // Typing after a refusal starts a new try; a wait the server asked for
        // goes on.
        status: state.status == ChangePasswordStatus.waiting
            ? ChangePasswordStatus.waiting
            : ChangePasswordStatus.editing,
        current: event.current,
        next: event.next,
        confirmation: event.confirmation,
        waitSecondsLeft: state.waitSecondsLeft,
      ),
    );
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    // A wait from the server is not over yet.
    if (!state.isValid || state.status == ChangePasswordStatus.waiting) return;
    emit(state.copyWith(status: ChangePasswordStatus.saving));
    try {
      final hadFingerprint = await _fingerprintIsOn();
      await _repository.changePassword(
        current: state.current,
        next: state.next,
      );
      emit(
        state.copyWith(
          status: ChangePasswordStatus.saved,
          offerFingerprint: hadFingerprint && await _fingerprintWasRemoved(),
        ),
      );
    } on WrongCredentialsException {
      emit(state.copyWith(status: ChangePasswordStatus.wrongCurrent));
    } on PasswordRejectedException catch (error) {
      emit(
        state.copyWith(
          status: ChangePasswordStatus.rejected,
          passwordProblem: error.problem,
        ),
      );
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        state.copyWith(
          status: ChangePasswordStatus.waiting,
          waitSecondsLeft: seconds,
        ),
      );
      _startWaitTimer(seconds);
    } on ServiceUnavailableException {
      emit(state.copyWith(status: ChangePasswordStatus.unavailable));
    } on NoConnectionException {
      emit(state.copyWith(status: ChangePasswordStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: ChangePasswordStatus.failure));
    }
  }

  /// Whether the fingerprint sign-in is on for this phone. A phone that
  /// cannot be asked counts as off: nothing is offered then.
  Future<bool> _fingerprintIsOn() async {
    try {
      return await _deviceKeys.isEnabled();
    } on Object {
      return false;
    }
  }

  /// Compares the phone with the server and says whether the key is gone, as
  /// it is after a password change.
  Future<bool> _fingerprintWasRemoved() async {
    try {
      await _deviceKeys.sync();
      return !await _deviceKeys.isEnabled();
    } on Object {
      return false;
    }
  }

  void _onWaitTicked(
    _ChangePasswordWaitTicked event,
    Emitter<ChangePasswordState> emit,
  ) {
    if (state.status != ChangePasswordStatus.waiting) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(waitSecondsLeft: event.secondsLeft)
          : state.copyWith(
              status: ChangePasswordStatus.editing,
              waitSecondsLeft: 0,
            ),
    );
  }

  void _startWaitTimer(int seconds) {
    unawaited(_waitTimer?.cancel());
    _waitTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_ChangePasswordWaitTicked(left)));
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
