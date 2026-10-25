import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

part 'device_key_list_event.dart';
part 'device_key_list_state.dart';

/// The "Phones with fingerprint sign-in" screen: the phones whose fingerprint
/// can sign the account in, and removing one. Removing the phone the app runs
/// on turns the sign-in off here too.
class DeviceKeyListBloc extends Bloc<DeviceKeyListEvent, DeviceKeyListState> {
  new({required this._repository}) : super(const DeviceKeyListState()) {
    on<DeviceKeyListStarted>(_onStarted, transformer: droppable());
    on<DeviceKeyListRetried>(_onRetried, transformer: droppable());
    // One removal at a time, in the order they were asked.
    on<DeviceKeyRemoved>(_onRemoved, transformer: sequential());
  }

  final DeviceKeyRepository _repository;

  Future<void> _onStarted(
    DeviceKeyListStarted event,
    Emitter<DeviceKeyListState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onRetried(
    DeviceKeyListRetried event,
    Emitter<DeviceKeyListState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onRemoved(
    DeviceKeyRemoved event,
    Emitter<DeviceKeyListState> emit,
  ) async {
    if (!state.keys.any((key) => key.deviceId == event.deviceId)) return;

    emit(state.copyWith(removingId: event.deviceId, clearFailure: true));
    try {
      await _repository.removeKey(event.deviceId);
      emit(
        state.copyWith(
          keys: [
            for (final key in state.keys)
              if (key.deviceId != event.deviceId) key,
          ],
          clearRemovingId: true,
          removedCount: state.removedCount + 1,
        ),
      );
    } on NoConnectionException {
      _failed(emit, event, DeviceKeyListFailure.offline);
    } on ServiceUnavailableException {
      _failed(emit, event, DeviceKeyListFailure.busy);
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      _failed(emit, event, DeviceKeyListFailure.other);
    }
  }

  void _failed(
    Emitter<DeviceKeyListState> emit,
    DeviceKeyRemoved event,
    DeviceKeyListFailure failure,
  ) {
    emit(
      state.copyWith(
        clearRemovingId: true,
        failedAction: event,
        failure: failure,
      ),
    );
  }

  Future<void> _load(Emitter<DeviceKeyListState> emit) async {
    emit(state.copyWith(status: DeviceKeyListStatus.loading));
    try {
      final keys = await _repository.keys();
      emit(state.copyWith(status: DeviceKeyListStatus.ready, keys: keys));
    } on NoConnectionException {
      emit(state.copyWith(status: DeviceKeyListStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: DeviceKeyListStatus.failure));
    }
  }
}
