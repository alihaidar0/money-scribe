import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

part 'transaction_form_event.dart';
part 'transaction_form_state.dart';

/// The Add transaction and Edit transaction form. Without an id it starts a
/// new transaction dated today in the first account; with one it loads that
/// transaction to be changed or deleted.
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  new({
    required this._transactions,
    required this._accounts,
    required this._categories,
    required DateTime Function() now,
    String? id,
  }) : _today = _day(now()),
       super(
         TransactionFormState(
           transactionId: id,
           values: TransactionFormValues(date: _day(now())),
           baseline: TransactionFormValues(date: _day(now())),
         ),
       ) {
    on<TransactionFormStarted>(_onStarted, transformer: droppable());
    on<TransactionFormRetried>(_onStarted, transformer: droppable());
    on<TransactionKindSelected>(_onKindSelected, transformer: sequential());
    on<TransactionAmountChanged>(_onAmountChanged, transformer: sequential());
    on<TransactionDateChosen>(_onDateChosen, transformer: sequential());
    on<TransactionPartChosen>(_onPartChosen, transformer: sequential());
    on<TransactionCategoryChosen>(_onCategoryChosen, transformer: sequential());
    on<TransactionAccountChosen>(_onAccountChosen, transformer: sequential());
    on<TransactionNoteChanged>(_onNoteChanged, transformer: sequential());
    on<TransactionAccountsRefreshed>(
      _onAccountsRefreshed,
      transformer: restartable(),
    );
    on<TransactionSaveRequested>(_onSaveRequested, transformer: droppable());
    on<TransactionDeleteRequested>(
      _onDeleteRequested,
      transformer: droppable(),
    );
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  final TransactionsRepository _transactions;
  final AccountsRepository _accounts;
  final CategoriesRepository _categories;

  /// The day of today, which a new transaction starts with.
  final DateTime _today;

  Future<void> _onStarted(
    TransactionFormEvent event,
    Emitter<TransactionFormState> emit,
  ) async {
    emit(state.copyWith(status: TransactionFormStatus.loading));
    final id = state.transactionId;
    try {
      final results = await Future.wait<Object?>([
        _accounts.accounts(),
        _categories.categories(),
        _transactions.payCycle(),
        if (id != null) _transactions.transaction(id),
      ]);
      final accounts = results[0]! as List<Account>;
      final categories = results[1]! as List<TransactionCategory>;
      final cycle = results[2]! as PayCycle;

      final TransactionFormValues values;
      if (id == null) {
        values = TransactionFormValues(
          date: _today,
          accountId: accounts.isEmpty ? null : accounts.first.id,
        );
      } else {
        final transaction = results[3] as Transaction?;
        if (transaction == null) {
          emit(state.copyWith(status: TransactionFormStatus.notFound));
          return;
        }
        values = TransactionFormValues(
          kind: transaction.kind,
          amountText: transaction.amount.toDecimalString(),
          date: transaction.date,
          categoryId: transaction.categoryId,
          accountId: transaction.accountId,
          note: transaction.note,
          // The part is shown as chosen only when it is not the nearest one.
          part: transaction.part == cycle.nearestPayEvent(transaction.date)
              ? null
              : transaction.part,
        );
      }
      final loaded = id == null ? null : results[3]! as Transaction;
      emit(
        state.copyWith(
          status: TransactionFormStatus.ready,
          accounts: accounts,
          categories: categories,
          cycle: cycle,
          values: values,
          baseline: values,
          // The currency of a transaction cannot be changed.
          currency: loaded?.amount.currency,
          version: loaded?.version,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: TransactionFormStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: TransactionFormStatus.failure));
    }
  }

  /// Loads the accounts again after they were managed. The chosen account
  /// stays unless it was deleted, and then the first one takes its place.
  Future<void> _onAccountsRefreshed(
    TransactionAccountsRefreshed event,
    Emitter<TransactionFormState> emit,
  ) async {
    try {
      final accounts = await _accounts.accounts();
      final chosen = state.values.accountId;
      final kept = accounts.any((account) => account.id == chosen);
      emit(
        state.copyWith(
          accounts: accounts,
          values: kept || accounts.isEmpty
              ? state.values
              : state.values.copyWith(accountId: accounts.first.id),
        ),
      );
    } on Exception catch (error, stackTrace) {
      // The list on screen is still good: keep it.
      addError(error, stackTrace);
    }
  }

  /// Reads the accounts and the categories again. A chosen account or category
  /// that is gone, or does not fit the kind, is dropped (the first account
  /// takes the place of a gone one), so the person chooses again.
  Future<void> _refreshChoices(Emitter<TransactionFormState> emit) async {
    try {
      final results = await Future.wait<Object?>([
        _accounts.accounts(),
        _categories.categories(),
      ]);
      final accounts = results[0]! as List<Account>;
      final categories = results[1]! as List<TransactionCategory>;
      var values = state.values;
      if (!accounts.any((account) => account.id == values.accountId)) {
        values = accounts.isEmpty
            ? values.copyWith(clearAccount: true)
            : values.copyWith(accountId: accounts.first.id);
      }
      final category = categories
          .where((category) => category.id == values.categoryId)
          .firstOrNull;
      if (category == null || !category.isFor(values.kind)) {
        values = values.copyWith(clearCategory: true);
      }
      emit(
        state.copyWith(
          accounts: accounts,
          categories: categories,
          values: values,
        ),
      );
    } on Exception catch (error, stackTrace) {
      // The lists on screen are still what the person can use: keep them.
      addError(error, stackTrace);
    }
  }

  void _edit(Emitter<TransactionFormState> emit, TransactionFormValues values) {
    emit(
      state.copyWith(
        values: values,
        // Edited since it was last saved.
        saveStatus: TransactionFormSaveStatus.idle,
      ),
    );
  }

  void _onKindSelected(
    TransactionKindSelected event,
    Emitter<TransactionFormState> emit,
  ) {
    if (event.kind == state.values.kind) return;
    var values = state.values.copyWith(kind: event.kind);
    // Only an income counts toward a part.
    if (event.kind != TransactionKind.income) {
      values = values.copyWith(clearPart: true);
    }

    // A category that does not fit the new kind is dropped.
    final category = state.categories
        .where((category) => category.id == values.categoryId)
        .firstOrNull;
    _edit(
      emit,
      category != null && !category.isFor(event.kind)
          ? values.copyWith(clearCategory: true)
          : values,
    );
  }

  void _onAmountChanged(
    TransactionAmountChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    _edit(emit, state.values.copyWith(amountText: event.text));
  }

  void _onDateChosen(
    TransactionDateChosen event,
    Emitter<TransactionFormState> emit,
  ) {
    final date = _day(event.date);
    var values = state.values.copyWith(date: date);
    // A chosen payment that is not around the new day is dropped: the income
    // goes back to the nearest one.
    final chosen = values.part;
    if (chosen != null && !state.cycle.payEventsAround(date).contains(chosen)) {
      values = values.copyWith(clearPart: true);
    }
    _edit(emit, values);
  }

  void _onPartChosen(
    TransactionPartChosen event,
    Emitter<TransactionFormState> emit,
  ) {
    final part = event.part;
    _edit(
      emit,
      part == null
          ? state.values.copyWith(clearPart: true)
          : state.values.copyWith(part: part),
    );
  }

  void _onCategoryChosen(
    TransactionCategoryChosen event,
    Emitter<TransactionFormState> emit,
  ) {
    _edit(emit, state.values.copyWith(categoryId: event.categoryId));
  }

  void _onAccountChosen(
    TransactionAccountChosen event,
    Emitter<TransactionFormState> emit,
  ) {
    _edit(emit, state.values.copyWith(accountId: event.accountId));
  }

  void _onNoteChanged(
    TransactionNoteChanged event,
    Emitter<TransactionFormState> emit,
  ) {
    _edit(emit, state.values.copyWith(note: event.text));
  }

  Future<void> _onSaveRequested(
    TransactionSaveRequested event,
    Emitter<TransactionFormState> emit,
  ) async {
    final draft = state.canSave ? state.draft : null;
    if (draft == null) return;

    // What is sent is what becomes the saved transaction, even if the person
    // types on while the server answers.
    final sent = state.values;
    emit(state.copyWith(saveStatus: TransactionFormSaveStatus.saving));
    try {
      final id = state.transactionId;
      final version = state.version;
      if (id == null || version == null) {
        await _transactions.add(draft);
      } else {
        await _transactions.update(id, draft, version: version);
      }
      emit(
        state.copyWith(
          saveStatus: TransactionFormSaveStatus.saved,
          baseline: sent,
        ),
      );
    } on StaleRecordException {
      emit(state.copyWith(saveStatus: TransactionFormSaveStatus.stale));
      add(const TransactionFormRetried());
    } on TransactionRefusedException catch (refused) {
      emit(
        state.copyWith(
          saveStatus: TransactionFormSaveStatus.refused,
          refusal: refused.refusal,
        ),
      );
      // The category or the account is not what the lists said: read them
      // again, so the person chooses from what exists.
      if (refused.refusal == TransactionRefusal.categoryOrAccountGone ||
          refused.refusal == TransactionRefusal.categoryNotAllowed) {
        await _refreshChoices(emit);
      }
    } on NoConnectionException {
      emit(state.copyWith(saveStatus: TransactionFormSaveStatus.failed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(saveStatus: TransactionFormSaveStatus.failed));
    }
  }

  Future<void> _onDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionFormState> emit,
  ) async {
    final id = state.transactionId;
    final version = state.version;
    if (id == null || version == null) return;

    emit(state.copyWith(deleteStatus: TransactionFormDeleteStatus.deleting));
    try {
      await _transactions.delete(id, version: version);
      emit(state.copyWith(deleteStatus: TransactionFormDeleteStatus.deleted));
    } on StaleRecordException {
      emit(state.copyWith(deleteStatus: TransactionFormDeleteStatus.stale));
      add(const TransactionFormRetried());
    } on NoConnectionException {
      emit(state.copyWith(deleteStatus: TransactionFormDeleteStatus.failed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(deleteStatus: TransactionFormDeleteStatus.failed));
    }
  }
}
