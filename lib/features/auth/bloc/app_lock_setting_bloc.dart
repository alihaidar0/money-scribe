import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';

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
  }

  final AppLockRepository _repository;

  Future<void> _onRefreshed(
    AppLockSettingRefreshed event,
    Emitter<AppLockSettingState> emit,
  ) async {
    try {
      emit(AppLockSettingState(isEnabled: await _repository.isEnabled()));
    } on Exception catch (error, stackTrace) {
      // The switch keeps what it showed.
      addError(error, stackTrace);
    }
  }

  Future<void> _onTurnedOff(
    AppLockTurnedOff event,
    Emitter<AppLockSettingState> emit,
  ) async {
    emit(const AppLockSettingState(isEnabled: true, isBusy: true));
    try {
      await _repository.disable();
      emit(const AppLockSettingState());
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const AppLockSettingState(isEnabled: true));
    }
  }
}
