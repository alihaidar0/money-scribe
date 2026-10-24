import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';

part 'app_lock_setting_event.dart';
part 'app_lock_setting_state.dart';

/// The App lock rows of the Settings: whether the lock is on, and turning it
/// off (turning it on needs a PIN, which the Create a PIN screen asks for, so
/// the switch only reports back); how long the app may stay away before it
/// locks; and the fingerprint switch, which turns on only after a fingerprint
/// matched and needs the PIN: turned on while the PIN lock is off, it asks for
/// the fingerprint first and then for a new PIN, and turns on when the PIN is
/// saved.
class AppLockSettingBloc
    extends Bloc<AppLockSettingEvent, AppLockSettingState> {
  new({required this._repository}) : super(const AppLockSettingState()) {
    on<AppLockSettingRefreshed>(_onRefreshed, transformer: restartable());
    on<AppLockTurnedOff>(_onTurnedOff, transformer: droppable());
    on<AppLockTimeoutChosen>(_onTimeoutChosen, transformer: sequential());
    on<BiometricsSwitched>(_onBiometricsSwitched, transformer: droppable());
    on<PinCreatedForFingerprint>(
      _onPinCreatedForFingerprint,
      transformer: droppable(),
    );
  }

  final AppLockRepository _repository;

  Future<void> _onRefreshed(
    AppLockSettingRefreshed event,
    Emitter<AppLockSettingState> emit,
  ) async {
    try {
      final isEnabled = await _repository.isEnabled();
      emit(
        AppLockSettingState(
          isEnabled: isEnabled,
          timeout: isEnabled
              ? await _repository.timeout()
              : LockTimeout.standard,
          biometricsAvailable: await _repository.biometricsAvailable(),
          biometricsEnabled: isEnabled && await _repository.biometricsEnabled(),
        ),
      );
    } on Exception catch (error, stackTrace) {
      // The switch keeps what it showed.
      addError(error, stackTrace);
    }
  }

  Future<void> _onPinCreatedForFingerprint(
    PinCreatedForFingerprint event,
    Emitter<AppLockSettingState> emit,
  ) async {
    try {
      final isEnabled = await _repository.isEnabled();
      // The PIN was saved: the fingerprint that was confirmed turns on with it.
      final fingerprintOn =
          isEnabled && await _repository.enableConfirmedBiometrics();
      emit(
        AppLockSettingState(
          isEnabled: isEnabled,
          timeout: isEnabled
              ? await _repository.timeout()
              : LockTimeout.standard,
          biometricsAvailable: state.biometricsAvailable,
          biometricsEnabled: fingerprintOn,
        ),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  Future<void> _onTurnedOff(
    AppLockTurnedOff event,
    Emitter<AppLockSettingState> emit,
  ) async {
    emit(
      AppLockSettingState(
        isEnabled: true,
        isBusy: true,
        timeout: state.timeout,
        biometricsAvailable: state.biometricsAvailable,
        biometricsEnabled: state.biometricsEnabled,
      ),
    );
    try {
      await _repository.disable();
      // The fingerprint goes with the lock, but the device still has it.
      emit(AppLockSettingState(biometricsAvailable: state.biometricsAvailable));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isBusy: false));
    }
  }

  Future<void> _onBiometricsSwitched(
    BiometricsSwitched event,
    Emitter<AppLockSettingState> emit,
  ) async {
    emit(state.copyWith(isBusy: true));
    try {
      if (event.turnOn && !state.isEnabled) {
        // No PIN yet: the fingerprint is confirmed first, so a finger that does
        // not match never leaves a PIN nobody meant to make; the PIN follows.
        final matched = await _repository.confirmBiometrics(
          reason: event.reason,
        );
        emit(
          state.copyWith(
            isBusy: false,
            biometricsRefused: !matched,
            pinNeeded: matched,
          ),
        );
      } else if (event.turnOn) {
        // On only when the fingerprint matched.
        final matched = await _repository.enableBiometrics(
          reason: event.reason,
        );
        emit(
          state.copyWith(
            isBusy: false,
            biometricsEnabled: matched,
            biometricsRefused: !matched,
          ),
        );
      } else {
        await _repository.disableBiometrics();
        emit(state.copyWith(isBusy: false, biometricsEnabled: false));
      }
    } on Exception catch (error, stackTrace) {
      // The switch keeps what it showed.
      addError(error, stackTrace);
      emit(state.copyWith(isBusy: false, biometricsRefused: event.turnOn));
    }
  }

  Future<void> _onTimeoutChosen(
    AppLockTimeoutChosen event,
    Emitter<AppLockSettingState> emit,
  ) async {
    try {
      await _repository.setTimeout(event.timeout);
      emit(state.copyWith(timeout: event.timeout));
    } on Exception catch (error, stackTrace) {
      // The row keeps the timeout it showed.
      addError(error, stackTrace);
    }
  }
}
