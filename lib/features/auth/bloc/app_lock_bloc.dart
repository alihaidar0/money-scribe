import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';

part 'app_lock_event.dart';
part 'app_lock_state.dart';

/// The App lock screen: opens the app with the fingerprint.
class AppLockBloc extends Bloc<AppLockEvent, AppLockState> {
  new({required this._repository}) : super(const AppLockState()) {
    // A second touch while the sensor is being read is ignored.
    on<BiometricUnlockRequested>(_onUnlockRequested, transformer: droppable());
  }

  final AppLockRepository _repository;

  Future<void> _onUnlockRequested(
    BiometricUnlockRequested event,
    Emitter<AppLockState> emit,
  ) async {
    emit(const AppLockState(status: AppLockStatus.checking));
    try {
      final matched = await _repository.unlockWithBiometrics();
      emit(
        AppLockState(
          status: matched
              ? AppLockStatus.unlocked
              : AppLockStatus.notRecognised,
        ),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const AppLockState(status: AppLockStatus.notRecognised));
    }
  }
}
