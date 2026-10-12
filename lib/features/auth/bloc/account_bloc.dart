import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

part 'account_event.dart';
part 'account_state.dart';

/// The account of the signed-in person: who they are, signing out and deleting
/// the account.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  new({required this._repository}) : super(const AccountState()) {
    on<AccountStarted>(_onStarted, transformer: droppable());
    on<AccountRetried>(_onStarted, transformer: droppable());
    // A second press while the first is being answered is ignored.
    on<SignOutConfirmed>(_onSignOutConfirmed, transformer: droppable());
    on<DeleteAccountConfirmed>(_onDeleteConfirmed, transformer: droppable());
    on<DeleteAccountDialogOpened>(
      _onDeleteDialogOpened,
      transformer: sequential(),
    );
  }

  final AuthRepository _repository;

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
    emit(state.copyWith(action: AccountAction.deleting));
    try {
      await _repository.deleteAccount(password: event.password);
      emit(state.copyWith(action: AccountAction.deleted));
    } on WrongCredentialsException {
      emit(state.copyWith(action: AccountAction.wrongPassword));
    } on NoConnectionException {
      emit(state.copyWith(action: AccountAction.deleteFailed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(action: AccountAction.deleteFailed));
    }
  }

  void _onDeleteDialogOpened(
    DeleteAccountDialogOpened event,
    Emitter<AccountState> emit,
  ) {
    emit(state.copyWith(action: AccountAction.none));
  }
}
