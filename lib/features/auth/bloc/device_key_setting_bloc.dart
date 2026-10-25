import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

part 'device_key_setting_event.dart';
part 'device_key_setting_state.dart';

/// The "Sign in with fingerprint" row of the Settings: whether the phone can
/// hold the key, whether the sign-in is on, and turning it on (the password,
/// then a fingerprint) and off.
class DeviceKeySettingBloc
    extends Bloc<DeviceKeySettingEvent, DeviceKeySettingState> {
  new({required this._repository}) : super(const DeviceKeySettingState()) {
    // The key can be made or removed from another screen (the password was
    // changed, a phone was removed): the switch follows.
    _changes = _repository.changes.listen(
      (_) => add(const DeviceKeySettingRefreshed()),
    );
    on<DeviceKeySettingRefreshed>(_onRefreshed, transformer: restartable());
    on<FingerprintSignInTurnedOn>(_onTurnedOn, transformer: droppable());
    on<FingerprintSignInTurnedOff>(_onTurnedOff, transformer: droppable());
  }

  final DeviceKeyRepository _repository;

  late final StreamSubscription<void> _changes;

  Future<void> _onRefreshed(
    DeviceKeySettingRefreshed event,
    Emitter<DeviceKeySettingState> emit,
  ) async {
    try {
      final support = await _repository.support();
      final enabled = await _repository.isEnabled();
      emit(
        state.copyWith(isLoaded: true, support: support, isEnabled: enabled),
      );
      if (!enabled) {
        return;
      }

      // The server may have dropped the key since (the password was changed,
      // another phone removed it): ask it, and show what is true.
      await _repository.sync();
      final stillEnabled = await _repository.isEnabled();
      if (stillEnabled != enabled) {
        emit(state.copyWith(isEnabled: stillEnabled));
      }
    } on Exception catch (error, stackTrace) {
      // The switch keeps what it showed.
      addError(error, stackTrace);
    }
  }

  Future<void> _onTurnedOn(
    FingerprintSignInTurnedOn event,
    Emitter<DeviceKeySettingState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, clearOutcome: true));
    try {
      await _repository.enable(password: event.password, prompt: event.prompt);
      emit(
        state.copyWith(
          isBusy: false,
          isEnabled: true,
          outcome: DeviceKeyOutcome.turnedOn,
        ),
      );
    } on RateLimitedException catch (error) {
      emit(
        state.copyWith(
          isBusy: false,
          outcome: DeviceKeyOutcome.waitForPassword,
          waitSeconds: error.retryAfter.ceilSeconds,
        ),
      );
    } on AuthException catch (error) {
      emit(state.copyWith(isBusy: false, outcome: _outcomeOf(error)));
    } on ServiceUnavailableException {
      emit(state.copyWith(isBusy: false, outcome: DeviceKeyOutcome.busy));
    } on NoConnectionException {
      emit(state.copyWith(isBusy: false, outcome: DeviceKeyOutcome.offline));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isBusy: false, outcome: DeviceKeyOutcome.failed));
    }
  }

  Future<void> _onTurnedOff(
    FingerprintSignInTurnedOff event,
    Emitter<DeviceKeySettingState> emit,
  ) async {
    emit(state.copyWith(isBusy: true, clearOutcome: true));
    try {
      await _repository.disable();
      emit(
        state.copyWith(
          isBusy: false,
          isEnabled: false,
          outcome: DeviceKeyOutcome.turnedOff,
        ),
      );
    } on ServiceUnavailableException {
      emit(state.copyWith(isBusy: false, outcome: DeviceKeyOutcome.busy));
    } on NoConnectionException {
      emit(state.copyWith(isBusy: false, outcome: DeviceKeyOutcome.offline));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isBusy: false, outcome: DeviceKeyOutcome.failed));
    }
  }

  DeviceKeyOutcome _outcomeOf(AuthException error) {
    return switch (error) {
      WrongCredentialsException() => DeviceKeyOutcome.wrongPassword,
      FingerprintCancelledException() => DeviceKeyOutcome.notMatched,
      FingerprintUnavailableException() ||
      FingerprintKeyInvalidatedException() => DeviceKeyOutcome.cannotCheck,
      FingerprintRefusedException(:final reason) => switch (reason) {
        FingerprintRefusal.limitReached => DeviceKeyOutcome.limitReached,
        FingerprintRefusal.challenge => DeviceKeyOutcome.expired,
        FingerprintRefusal.attestation ||
        FingerprintRefusal.platform ||
        FingerprintRefusal.publicKey ||
        FingerprintRefusal.signInFailed => DeviceKeyOutcome.refused,
      },
      _ => DeviceKeyOutcome.failed,
    };
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }
}
