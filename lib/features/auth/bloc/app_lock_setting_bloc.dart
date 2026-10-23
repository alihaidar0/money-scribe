import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';

part 'app_lock_setting_event.dart';
part 'app_lock_setting_state.dart';

/// The "App lock" switch of the Settings: whether the lock is on, and turning
/// it off. Turning it on needs a PIN, which the Create a PIN screen asks for,
/// so the switch only reports back.
class AppLockSettingBloc
    extends Bloc<AppLockSettingEvent, AppLockSettingState> {
  new({required this._repository}) : super(const AppLockSettingState()) {
    on<AppLockSettingRefreshed>(_onRefreshed, transformer: restartable());
    on<AppLockTurnedOff>(_onTurnedOff, transformer: droppable());
    on<AppLockTimeoutChosen>(_onTimeoutChosen, transformer: sequential());
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
        ),
      );
    } on Exception catch (error, stackTrace) {
      // The switch keeps what it showed.
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
      ),
    );
    try {
      await _repository.disable();
      emit(const AppLockSettingState());
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(AppLockSettingState(isEnabled: true, timeout: state.timeout));
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
