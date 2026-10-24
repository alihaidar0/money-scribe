import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

part 'account_event.dart';
part 'account_state.dart';

/// The account of the signed-in person: who they are, signing out and deleting
/// the account.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  new({
    required this._repository,
    required this._appLock,
    required this._deviceKeys,
    required this._ticker,
  }) : super(const AccountState()) {
    on<AccountStarted>(_onStarted, transformer: droppable());
    on<AccountRetried>(_onStarted, transformer: droppable());
    // A second press while the first is being answered is ignored.
    on<SignOutConfirmed>(_onSignOutConfirmed, transformer: droppable());
    on<DeleteAccountConfirmed>(_onDeleteConfirmed, transformer: droppable());
    on<DeleteAccountDialogOpened>(
      _onDeleteDialogOpened,
      transformer: sequential(),
    );
    on<_DeleteWaitTicked>(_onDeleteWaitTicked, transformer: sequential());
    on<AccountProfileChanged>(_onProfileChanged, transformer: sequential());
  }

  final AuthRepository _repository;
  final AppLockRepository _appLock;
  final DeviceKeyRepository _deviceKeys;
  final Ticker _ticker;
  StreamSubscription<int>? _waitTimer;

  Future<void> _onStarted(
    AccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loading));
    try {
      final profile = await _repository.profile();
      emit(state.copyWith(status: AccountStatus.ready, profile: profile));
    } on NoConnectionException {
      emit(state.copyWith(status: AccountStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: AccountStatus.failure));
    }
  }

  Future<void> _onSignOutConfirmed(
    SignOutConfirmed event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(action: AccountAction.signingOut));
    try {
      // The router sees the account is signed out and leaves the screen.
      await _repository.signOut();
      emit(state.copyWith(action: AccountAction.none));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(action: AccountAction.signOutFailed));
    }
  }

  Future<void> _onDeleteConfirmed(
    DeleteAccountConfirmed event,
    Emitter<AccountState> emit,
  ) async {
    // A wait from the server is not over yet.
    if (state.action == AccountAction.deleteWaiting) return;
    emit(state.copyWith(action: AccountAction.deleting));
    try {
      await _repository.deleteAccount(password: event.password);
      // The account is gone, and so are the lock that guarded it and the
      // fingerprint key that signed it in (the server deleted its half).
      await _forgetLock();
      await _deviceKeys.forgetLocal();
      emit(state.copyWith(action: AccountAction.deleted));
    } on WrongCredentialsException {
      emit(state.copyWith(action: AccountAction.wrongPassword));
    } on RateLimitedException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        state.copyWith(
          action: AccountAction.deleteWaiting,
          deleteWaitSecondsLeft: seconds,
        ),
      );
      unawaited(_waitTimer?.cancel());
      _waitTimer = _ticker
          .countdown(seconds)
          .listen((left) => add(_DeleteWaitTicked(left)));
    } on ServiceUnavailableException {
      emit(state.copyWith(action: AccountAction.deleteUnavailable));
    } on NoConnectionException {
      emit(state.copyWith(action: AccountAction.deleteFailed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(action: AccountAction.deleteFailed));
    }
  }

  Future<void> _forgetLock() async {
    try {
      await _appLock.disable();
    } on Exception catch (error, stackTrace) {
      // The account is deleted all the same; a leftover lock belongs to an
      // account that no longer exists, and goes at the next sign-in.
      addError(error, stackTrace);
    }
  }

  void _onDeleteDialogOpened(
    DeleteAccountDialogOpened event,
    Emitter<AccountState> emit,
  ) {
    // Opening the dialog again does not end a wait the server asked for.
    if (state.action == AccountAction.deleteWaiting) return;
    emit(state.copyWith(action: AccountAction.none));
  }

  void _onProfileChanged(
    AccountProfileChanged event,
    Emitter<AccountState> emit,
  ) {
    emit(state.copyWith(status: AccountStatus.ready, profile: event.profile));
  }

  void _onDeleteWaitTicked(
    _DeleteWaitTicked event,
    Emitter<AccountState> emit,
  ) {
    if (state.action != AccountAction.deleteWaiting) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(deleteWaitSecondsLeft: event.secondsLeft)
          : state.copyWith(
              action: AccountAction.none,
              deleteWaitSecondsLeft: 0,
            ),
    );
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
