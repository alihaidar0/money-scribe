import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/app_lock_session.dart';

part 'app_lock_event.dart';
part 'app_lock_state.dart';

/// The App lock screen: opens the app with the fingerprint when the device
/// has one, and leads to the PIN otherwise.
class AppLockBloc extends Bloc<AppLockEvent, AppLockState> {
  new({required this._repository, required this._session})
    : super(const AppLockState()) {
    on<AppLockStarted>(_onStarted, transformer: droppable());
    // A second touch while the sensor is being read is ignored.
    on<BiometricUnlockRequested>(_onUnlockRequested, transformer: droppable());
  }

  final AppLockRepository _repository;
  final AppLockSession _session;

  Future<void> _onStarted(
    AppLockStarted event,
    Emitter<AppLockState> emit,
  ) async {
    final canUse = await _canUseBiometrics();
    emit(AppLockState(canUseBiometrics: canUse));
    // The fingerprint is the quick way in: ask for it at once.
    if (canUse) await _unlock(event.reason, emit);
  }

  Future<void> _onUnlockRequested(
    BiometricUnlockRequested event,
    Emitter<AppLockState> emit,
  ) => _unlock(event.reason, emit);

  Future<void> _unlock(String reason, Emitter<AppLockState> emit) async {
    emit(state.copyWith(status: AppLockStatus.checking));
    try {
      final matched = await _repository.unlockWithBiometrics(reason: reason);
      if (matched) _session.unlock();
      emit(
        state.copyWith(
          status: matched
              ? AppLockStatus.unlocked
              : AppLockStatus.notRecognised,
        ),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: AppLockStatus.notRecognised));
    }
  }

  Future<bool> _canUseBiometrics() async {
    try {
      return await _repository.canUseBiometrics();
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      return false;
    }
  }
}
