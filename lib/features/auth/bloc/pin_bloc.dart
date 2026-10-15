import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

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
  new({required this._mode, required this._appLock, required this._auth})
    : super(const PinState()) {
    // Keys pressed while a PIN is being checked are ignored.
    on<PinDigitPressed>(_onDigitPressed, transformer: droppable());
    on<PinBackspacePressed>(_onBackspacePressed, transformer: sequential());
    on<ForgotPinPressed>(_onForgotPinPressed, transformer: droppable());
  }

  /// How many digits a PIN has.
  static const pinLength = 4;

  final PinMode _mode;
  final AppLockRepository _appLock;
  final AuthRepository _auth;

  /// The PIN typed first, while the person repeats it.
  String? _firstPin;

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
    await _auth.signOut();
    emit(state.copyWith(status: PinStatus.signedOut));
  }

  Future<void> _unlock(String pin, Emitter<PinState> emit) async {
    emit(state.copyWith(status: PinStatus.checking));
    try {
      final matches = await _appLock.verifyPin(pin);
      emit(
        matches
            ? state.copyWith(status: PinStatus.accepted)
            : state.copyWith(pin: '', status: PinStatus.wrong),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(pin: '', status: PinStatus.wrong));
    }
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
      await _appLock.savePin(pin);
      emit(state.copyWith(status: PinStatus.accepted));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      _firstPin = null;
      emit(const PinState(status: PinStatus.mismatch));
    }
  }
}
