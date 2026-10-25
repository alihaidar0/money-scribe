import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_session.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';

part 'pin_event.dart';
part 'pin_state.dart';

/// What the PIN pad is for.
enum PinMode {
  /// Enter the saved PIN to open the app.
  unlock,

  /// Choose a new PIN: type it, then repeat it.
  create,
}

/// The PIN pad of the PIN entry and Create a PIN screens.
class PinBloc extends Bloc<PinEvent, PinState> {
  new({
    required this._mode,
    required this._appLock,
    required this._auth,
    required this._session,
    required this._ticker,
  }) : super(const PinState()) {
    on<PinStarted>(_onStarted, transformer: droppable());
    // Keys pressed while a PIN is being checked are ignored.
    on<PinDigitPressed>(_onDigitPressed, transformer: droppable());
    on<PinBackspacePressed>(_onBackspacePressed, transformer: sequential());
    on<ForgotPinPressed>(_onForgotPinPressed, transformer: droppable());
    on<_PinPauseTicked>(_onPauseTicked, transformer: sequential());
  }

  /// How many digits a PIN has.
  static const pinLength = 4;

  final PinMode _mode;
  final AppLockRepository _appLock;
  final AuthRepository _auth;
  final AppLockSession _session;
  final Ticker _ticker;
  StreamSubscription<int>? _pauseTimer;

  /// The PIN typed first, while the person repeats it.
  String? _firstPin;

  /// A pause after wrong PINs survives a restart: the screen may open in the
  /// middle of one.
  Future<void> _onStarted(PinStarted event, Emitter<PinState> emit) async {
    if (_mode != PinMode.unlock) return;
    try {
      final remaining = await _appLock.pinPauseRemaining();
      if (remaining != null) _pause(remaining, emit);
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  Future<void> _onDigitPressed(
    PinDigitPressed event,
    Emitter<PinState> emit,
  ) async {
    if (state.isBusy || state.pin.length >= pinLength) return;
    final pin = '${state.pin}${event.digit}';
    // A key pressed after an error starts a new try.
    emit(state.copyWith(pin: pin, status: PinStatus.entering));
    if (pin.length < pinLength) return;

    switch (_mode) {
      case PinMode.unlock:
        await _unlock(pin, emit);
      case PinMode.create:
        await _create(pin, emit);
    }
  }

  void _onBackspacePressed(PinBackspacePressed event, Emitter<PinState> emit) {
    if (state.isBusy || state.pin.isEmpty) return;
    emit(
      state.copyWith(
        pin: state.pin.substring(0, state.pin.length - 1),
        status: PinStatus.entering,
      ),
    );
  }

  Future<void> _onForgotPinPressed(
    ForgotPinPressed event,
    Emitter<PinState> emit,
  ) async {
    // The PIN is what was forgotten: the lock goes, and a new one is made after
    // signing in again.
    await _appLock.disable();
    await _auth.signOut();
    emit(state.copyWith(status: PinStatus.signedOut));
  }

  Future<void> _unlock(String pin, Emitter<PinState> emit) async {
    emit(state.copyWith(status: PinStatus.checking));
    try {
      switch (await _appLock.checkPin(pin)) {
        case PinAccepted():
          _session.unlock();
          emit(state.copyWith(status: PinStatus.accepted));
        case PinWrong(:final delay):
          if (delay == null) {
            emit(state.copyWith(pin: '', status: PinStatus.wrong));
          } else {
            _pause(delay, emit);
          }
        case PinPaused(:final remaining):
          _pause(remaining, emit);
        case PinTooManyFailures():
          // The PIN is no longer a way in: only the password opens the app, and
          // the lock goes with it.
          await _appLock.disable();
          await _auth.signOut();
          emit(state.copyWith(pin: '', status: PinStatus.tooManyFailures));
      }
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(pin: '', status: PinStatus.wrong));
    }
  }

  void _pause(Duration duration, Emitter<PinState> emit) {
    final seconds = duration.ceilSeconds;
    emit(
      state.copyWith(
        pin: '',
        status: PinStatus.paused,
        pauseSecondsLeft: seconds,
      ),
    );
    unawaited(_pauseTimer?.cancel());
    _pauseTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_PinPauseTicked(left)));
  }

  void _onPauseTicked(_PinPauseTicked event, Emitter<PinState> emit) {
    if (state.status != PinStatus.paused) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(pauseSecondsLeft: event.secondsLeft)
          : state.copyWith(status: PinStatus.entering, pauseSecondsLeft: 0),
    );
  }

  @override
  Future<void> close() async {
    await _pauseTimer?.cancel();
    await super.close();
  }

  Future<void> _create(String pin, Emitter<PinState> emit) async {
    final first = _firstPin;
    if (first == null) {
      _firstPin = pin;
      emit(const PinState(stage: PinStage.repeat));
      return;
    }
    if (first != pin) {
      _firstPin = null;
      emit(const PinState(status: PinStatus.mismatch));
      return;
    }
    emit(state.copyWith(status: PinStatus.checking));
    try {
      await _appLock.savePin(pin, accountId: _auth.accountId);
      emit(state.copyWith(status: PinStatus.accepted));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      _firstPin = null;
      emit(const PinState(status: PinStatus.mismatch));
    }
  }
}
