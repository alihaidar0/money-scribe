import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

/// The Accounts screen of the Settings: the accounts, which can be added,
/// changed and, while they have no transactions, deleted.
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  new({required this._repository}) : super(const AccountsState()) {
    on<AccountsStarted>(_onStarted, transformer: droppable());
    on<AccountsRetried>(_onStarted, transformer: droppable());
    // One at a time, so the list is always what the last change made it.
    on<AccountAdded>(_onAdded, transformer: sequential());
    on<AccountChanged>(_onChanged, transformer: sequential());
    on<AccountDeleted>(_onDeleted, transformer: sequential());
  }

  final AccountsRepository _repository;

  Future<void> _onStarted(
    AccountsEvent event,
    Emitter<AccountsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AccountsStatus.loading,
        deleteBlocked: false,
        clearFailedAction: true,
        clearStaleAction: true,
        clearRefusal: true,
      ),
    );
    try {
      final accounts = await _repository.accounts();
      emit(state.copyWith(status: AccountsStatus.ready, accounts: accounts));
    } on NoConnectionException {
      emit(state.copyWith(status: AccountsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: AccountsStatus.failure));
    }
  }

  Future<void> _onAdded(AccountAdded event, Emitter<AccountsState> emit) {
    return _run(event, emit, () async {
      final account = await _repository.add(event.draft);
      emit(state.copyWith(accounts: [...state.accounts, account]));
    });
  }

  Future<void> _onChanged(AccountChanged event, Emitter<AccountsState> emit) {
    return _run(event, emit, () async {
      final account = await _repository.update(
        event.id,
        event.draft,
        version: _accountOf(event.id).version,
      );
      emit(
        state.copyWith(
          accounts: [
            for (final item in state.accounts)
              if (item.id == event.id) account else item,
          ],
        ),
      );
    });
  }

  Future<void> _onDeleted(AccountDeleted event, Emitter<AccountsState> emit) {
    return _run(event, emit, () async {
      try {
        await _repository.delete(
          event.id,
          version: _accountOf(event.id).version,
        );
      } on AccountInUseException {
        emit(state.copyWith(deleteBlocked: true));
        return;
      }
      emit(
        state.copyWith(
          accounts: [
            for (final item in state.accounts)
              if (item.id != event.id) item,
          ],
        ),
      );
    });
  }

  /// The account [id] as the list shows it. An account that is not there was
  /// deleted on another device, which is the same as a version that moved on.
  Account _accountOf(String id) {
    return state.accounts.firstWhere(
      (account) => account.id == id,
      orElse: () => throw const StaleRecordException(),
    );
  }

  /// Does [action], which saves [event] on the server. When the server does
  /// not accept it the list stays as it was and [AccountsState.failedAction]
  /// holds [event], so the screen can offer to try again. When the account was
  /// changed on another device the list is loaded again and
  /// [AccountsState.staleAction] holds [event], so the screen can offer to
  /// apply it to what is there now. When the name is taken or there are too
  /// many accounts, [AccountsState.refusal] says so.
  Future<void> _run(
    AccountsEvent event,
    Emitter<AccountsState> emit,
    Future<void> Function() action,
  ) async {
    emit(
      state.copyWith(
        deleteBlocked: false,
        clearFailedAction: true,
        clearStaleAction: true,
        clearRefusal: true,
      ),
    );
    try {
      await action();
    } on StaleRecordException {
      await _reload(emit);
      emit(state.copyWith(staleAction: event));
    } on AccountRefusedException catch (refused) {
      emit(state.copyWith(refusal: refused.refusal));
    } on NoConnectionException {
      emit(state.copyWith(failedAction: event));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(failedAction: event));
    }
  }

  /// Reads the accounts again without the loading state. If the server cannot
  /// be reached the list stays as it was.
  Future<void> _reload(Emitter<AccountsState> emit) async {
    try {
      emit(state.copyWith(accounts: await _repository.accounts()));
    } on Exception {
      // The list stays; the next load asks again.
    }
  }
}
