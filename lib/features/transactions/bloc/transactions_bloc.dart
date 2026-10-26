import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transactions_page.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

/// The Transactions screen: the transactions, narrowed by a search, filters
/// and, for two payments, a part of the month.
///
/// The server does the narrowing and cuts the list into pages, the newest
/// first. The Bloc loads the first page, then one more each time the end of
/// the list comes into view, and reads the totals of the days in step, so a
/// day always has its total next to its transactions. The search waits a
/// moment after the last key before it asks.
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  new({
    required this._transactions,
    required this._accounts,
    required this._categories,
    this._pageSize = TransactionsRepository.defaultPageSize,
    this._searchDelay = defaultSearchDelay,
  }) : super(const TransactionsState()) {
    _changes = _transactions.changes.listen(
      (_) => add(const TransactionsDataChanged()),
    );
    // A category or an account changed in the Settings: show the new names
    // without the loading state.
    _listChanges = [
      _categories.changes.listen((_) => add(const TransactionsRefreshed())),
      _accounts.changes.listen((_) => add(const TransactionsRefreshed())),
    ];
    on<TransactionsStarted>(_onStarted, transformer: droppable());
    on<TransactionsRetried>(_onRetried, transformer: droppable());
    on<TransactionsDataChanged>(_onDataChanged, transformer: restartable());
    on<TransactionsRefreshed>(_onRefreshed, transformer: restartable());
    on<TransactionsMoreRequested>(_onMoreRequested, transformer: droppable());
    on<TransactionsMoreRetried>(_onMoreRequested, transformer: droppable());
    on<TransactionsSearched>(_onSearched, transformer: restartable());
    on<TransactionFiltersApplied>(
      _onFiltersApplied,
      transformer: restartable(),
    );
    on<TransactionFiltersCleared>(
      _onFiltersCleared,
      transformer: restartable(),
    );
    on<TransactionsScopeSelected>(_onScopeSelected, transformer: restartable());
    on<TransactionSelected>(_onSelected, transformer: sequential());
    on<TransactionDeleteConfirmed>(
      _onDeleteConfirmed,
      transformer: droppable(),
    );
  }

  /// How long the search waits after the last key before it asks the server.
  static const defaultSearchDelay = Duration(milliseconds: 500);

  /// The most pages that add nothing to the list that are loaded one after the
  /// other while a part of the month is chosen, before the list waits for the
  /// person to scroll.
  static const _maxEmptyPages = 10;

  final TransactionsRepository _transactions;
  final AccountsRepository _accounts;
  final CategoriesRepository _categories;
  final int _pageSize;
  final Duration _searchDelay;

  late final StreamSubscription<void> _changes;
  late final List<StreamSubscription<void>> _listChanges;

  /// Whether the accounts, the categories and how the salary is paid are
  /// loaded. The screen is shown once they and the first page of the results
  /// are, whichever comes last: a filter applied as the screen opens loads its
  /// results on its own.
  var _screenLoaded = false;

  /// Counts the loads of the first page. An answer that comes after a newer
  /// load started (the person typed on, or changed a filter) belongs to a list
  /// that is no longer asked for and is dropped.
  var _generation = 0;

  Future<void> _onStarted(
    TransactionsStarted event,
    Emitter<TransactionsState> emit,
  ) {
    return _loadScreen(emit, showLoading: true);
  }

  Future<void> _onRetried(
    TransactionsRetried event,
    Emitter<TransactionsState> emit,
  ) {
    // Under a failed search the screen is shown: only the results load again.
    if (state.status == TransactionsStatus.ready) {
      return _loadResults(emit, showLoading: true);
    }
    return _loadScreen(emit, showLoading: true);
  }

  Future<void> _onDataChanged(
    TransactionsDataChanged event,
    Emitter<TransactionsState> emit,
  ) {
    return _loadScreen(emit, showLoading: true);
  }

  Future<void> _onRefreshed(
    TransactionsRefreshed event,
    Emitter<TransactionsState> emit,
  ) {
    return _loadScreen(emit, showLoading: false);
  }

  Future<void> _onSearched(
    TransactionsSearched event,
    Emitter<TransactionsState> emit,
  ) async {
    final before = state.filter.searchTerm;
    final filter = state.filter.withQuery(event.query);
    emit(state.copyWith(filter: filter));
    // One letter is not a search: nothing changes for the server until there
    // are enough, and a change that leaves the words as they were asks nothing.
    if (filter.searchTerm == before) return;

    await Future<void>.delayed(_searchDelay);
    if (emit.isDone) return;
    await _loadResults(emit, showLoading: true);
  }

  Future<void> _onFiltersApplied(
    TransactionFiltersApplied event,
    Emitter<TransactionsState> emit,
  ) {
    final filter = state.filter.withSheetFiltersOf(event.filter);
    final changed = filter != state.filter;
    emit(state.copyWith(filter: filter, scope: event.scope));
    // Only the part of the month changed: the loaded pages are cut differently,
    // nothing is asked again.
    if (!changed) return _fillPart(emit, _generation);
    return _loadResults(emit, showLoading: true);
  }

  Future<void> _onFiltersCleared(
    TransactionFiltersCleared event,
    Emitter<TransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        filter: const TransactionFilter(),
        scope: PeriodScope.month,
      ),
    );
    return _loadResults(emit, showLoading: true);
  }

  Future<void> _onScopeSelected(
    TransactionsScopeSelected event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(scope: event.scope));
    // The part is cut from the pages that are loaded; more are loaded only if
    // the part shows too little.
    return _fillPart(emit, _generation);
  }

  void _onSelected(TransactionSelected event, Emitter<TransactionsState> emit) {
    emit(state.copyWith(selectedId: event.id));
  }

  Future<void> _onDeleteConfirmed(
    TransactionDeleteConfirmed event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteStatus: TransactionsDeleteStatus.deleting,
        deletingId: event.id,
      ),
    );
    try {
      final transaction = state.transactions
          .where((item) => item.id == event.id)
          .firstOrNull;
      // A transaction that is not in the list was deleted on another device.
      if (transaction != null) {
        await _transactions.delete(event.id, version: transaction.version);
      }
    } on StaleRecordException {
      emit(state.copyWith(deleteStatus: TransactionsDeleteStatus.stale));
      await _loadResults(emit, showLoading: false);
      return;
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      if (error is! NoConnectionException) addError(error, stackTrace);
      emit(state.copyWith(deleteStatus: TransactionsDeleteStatus.failed));
      return;
    }
    emit(state.copyWith(deleteStatus: TransactionsDeleteStatus.idle));
    await _loadResults(emit, showLoading: false);
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    for (final subscription in _listChanges) {
      await subscription.cancel();
    }
    await super.close();
  }

  /// Loads what the screen is made of: the accounts and categories whose names
  /// the rows show, how the salary is paid, and the first page of the results.
  Future<void> _loadScreen(
    Emitter<TransactionsState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      _screenLoaded = false;
      emit(state.copyWith(status: TransactionsStatus.loading));
    }
    try {
      final results = await Future.wait<Object?>([
        _accounts.accounts(),
        _categories.categories(),
        _transactions.paymentMode(),
      ]);
      if (emit.isDone) return;
      emit(
        state.copyWith(
          accounts: results[0]! as List<Account>,
          categories: results[1]! as List<TransactionCategory>,
          twoPayments: results[2] == PaymentMode.twoPayments,
        ),
      );
      _screenLoaded = true;
    } on NoConnectionException {
      if (emit.isDone) return;
      emit(state.copyWith(status: TransactionsStatus.noConnection));
      return;
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(status: TransactionsStatus.failure));
      return;
    }
    await _loadResults(emit, showLoading: showLoading);
  }

  /// Loads the first page of the transactions that pass the search and the
  /// filters, with the totals of its days. With [showLoading] the old results
  /// give way to the loading state; without it they stay until the new ones
  /// come. While the screen is not shown yet, a failure is the failure of the
  /// whole screen.
  Future<void> _loadResults(
    Emitter<TransactionsState> emit, {
    required bool showLoading,
  }) async {
    final generation = ++_generation;
    if (showLoading) {
      emit(
        state.copyWith(
          resultsStatus: TransactionsResultsStatus.loading,
          transactions: const [],
          dayTotals: const {},
          clearNextCursor: true,
          clearNextDayTotalsCursor: true,
          loadingMore: false,
          loadMoreFailed: false,
        ),
      );
    }
    try {
      final filter = state.filter;
      final fetched = await Future.wait<Object?>([
        _transactions.transactions(filter, pageSize: _pageSize),
        if (!filter.isSearching)
          _transactions.dayTotals(filter, pageSize: _pageSize),
      ]);
      if (emit.isDone || generation != _generation) return;

      final page = fetched[0]! as TransactionsPage;
      final totals = fetched.length > 1 ? fetched[1]! as DayTotalsPage : null;
      emit(
        state.copyWith(
          // A filter that is applied while the names are still loading waits
          // for them: the screen is shown when both are there.
          status: _screenLoaded ? TransactionsStatus.ready : null,
          resultsStatus: TransactionsResultsStatus.ready,
          transactions: page.items,
          nextCursor: page.nextCursor,
          dayTotals: totals == null ? const {} : _totalsByDay(totals.days),
          nextDayTotalsCursor: totals?.nextCursor,
          clearNextCursor: page.nextCursor == null,
          clearNextDayTotalsCursor: totals?.nextCursor == null,
          loadingMore: false,
          loadMoreFailed: false,
          // Nothing narrowed the list: now it is known whether there is any.
          hasTransactions: state.isNarrowed ? null : page.items.isNotEmpty,
        ),
      );
      await _fillPart(emit, generation);
    } on NoConnectionException {
      if (emit.isDone || generation != _generation) return;
      emit(
        state.status != TransactionsStatus.ready
            ? state.copyWith(status: TransactionsStatus.noConnection)
            : state.copyWith(
                resultsStatus: TransactionsResultsStatus.noConnection,
              ),
      );
    } on Exception catch (error, stackTrace) {
      if (emit.isDone || generation != _generation) return;
      addError(error, stackTrace);
      emit(
        state.status != TransactionsStatus.ready
            ? state.copyWith(status: TransactionsStatus.failure)
            : state.copyWith(resultsStatus: TransactionsResultsStatus.failure),
      );
    }
  }

  Future<void> _onMoreRequested(
    TransactionsEvent event,
    Emitter<TransactionsState> emit,
  ) async {
    if (state.nextCursor == null || state.loadingMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      await _loadNextPage(emit, generation);
      if (emit.isDone || generation != _generation) return;
      emit(state.copyWith(loadingMore: false));
      await _fillPart(emit, generation);
    } on Exception catch (error, stackTrace) {
      if (emit.isDone || generation != _generation) return;
      if (error is! NoConnectionException) addError(error, stackTrace);
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  /// While a part of the month is chosen, a page can hold no day of it. The
  /// list would then show nothing and, with nothing to scroll, never ask for
  /// more: pages are loaded one after the other until something shows, up to
  /// [_maxEmptyPages].
  Future<void> _fillPart(
    Emitter<TransactionsState> emit,
    int generation,
  ) async {
    var empty = 0;
    while (state.filtersByPart &&
        state.nextCursor != null &&
        state.visible.length < _pageSize ~/ 2 &&
        empty < _maxEmptyPages) {
      final before = state.visible.length;
      emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
      try {
        await _loadNextPage(emit, generation);
      } on Exception catch (error, stackTrace) {
        if (emit.isDone || generation != _generation) return;
        if (error is! NoConnectionException) addError(error, stackTrace);
        emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
        return;
      }
      if (emit.isDone || generation != _generation) return;
      emit(state.copyWith(loadingMore: false));
      empty = state.visible.length == before ? empty + 1 : 0;
    }
  }

  /// Loads the page after the last one, and the pages of day totals needed so
  /// every loaded day has its total.
  Future<void> _loadNextPage(
    Emitter<TransactionsState> emit,
    int generation,
  ) async {
    final filter = state.filter;
    final page = await _transactions.transactions(
      filter,
      cursor: state.nextCursor,
      pageSize: _pageSize,
    );
    if (emit.isDone || generation != _generation) return;

    final transactions = [...state.transactions, ...page.items];
    var totals = state.dayTotals;
    var totalsCursor = state.nextDayTotalsCursor;
    if (!filter.isSearching && transactions.isNotEmpty) {
      final oldest = transactions.last.date;
      // The totals are newest first: load pages until they reach the oldest
      // day of the list, or there are no more.
      while (totalsCursor != null && !_covers(totals, oldest)) {
        final more = await _transactions.dayTotals(
          filter,
          cursor: totalsCursor,
          pageSize: _pageSize,
        );
        if (emit.isDone || generation != _generation) return;
        totals = {...totals, ..._totalsByDay(more.days)};
        totalsCursor = more.nextCursor;
      }
    }
    emit(
      state.copyWith(
        transactions: transactions,
        nextCursor: page.nextCursor,
        dayTotals: totals,
        nextDayTotalsCursor: totalsCursor,
        clearNextCursor: page.nextCursor == null,
        clearNextDayTotalsCursor: totalsCursor == null,
      ),
    );
  }

  /// Whether [totals] reach back to [day] (they are loaded newest first).
  static bool _covers(Map<DateTime, List<Money>> totals, DateTime day) {
    return totals.keys.any((date) => !date.isAfter(day));
  }

  static Map<DateTime, List<Money>> _totalsByDay(List<DayTotal> days) {
    return {for (final day in days) day.date: day.totals};
  }
}
