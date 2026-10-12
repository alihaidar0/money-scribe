import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/accounts_repository.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';
import 'package:money_scribe/features/transactions/domain/transactions_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

/// The Transactions screen: every transaction, narrowed by a search, filters
/// and, for two payments, a part of the month.
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  new({
    required this._transactions,
    required this._accounts,
    required this._categories,
  }) : super(const TransactionsState()) {
    _changes = _transactions.changes.listen(
      (_) => add(const TransactionsDataChanged()),
    );
    on<TransactionsStarted>(_onStarted, transformer: droppable());
    on<TransactionsRetried>(_onRetried, transformer: droppable());
    on<TransactionsDataChanged>(_onDataChanged, transformer: restartable());
    on<TransactionsRefreshed>(_onRefreshed, transformer: restartable());
    on<TransactionsSearched>(_onSearched, transformer: sequential());
    on<TransactionFiltersApplied>(_onFiltersApplied, transformer: sequential());
    on<TransactionFiltersCleared>(_onFiltersCleared, transformer: sequential());
    on<TransactionsScopeSelected>(_onScopeSelected, transformer: sequential());
  }

  final TransactionsRepository _transactions;
  final AccountsRepository _accounts;
  final CategoriesRepository _categories;

  late final StreamSubscription<void> _changes;

  Future<void> _onStarted(
    TransactionsStarted event,
    Emitter<TransactionsState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onRetried(
    TransactionsRetried event,
    Emitter<TransactionsState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onDataChanged(
    TransactionsDataChanged event,
    Emitter<TransactionsState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onRefreshed(
    TransactionsRefreshed event,
    Emitter<TransactionsState> emit,
  ) {
    return _load(emit, showLoading: false);
  }

  void _onSearched(
    TransactionsSearched event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(filter: state.filter.withQuery(event.query)));
  }

  void _onFiltersApplied(
    TransactionFiltersApplied event,
    Emitter<TransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        filter: state.filter.withSheetFiltersOf(event.filter),
        scope: event.scope,
      ),
    );
  }

  void _onFiltersCleared(
    TransactionFiltersCleared event,
    Emitter<TransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        filter: const TransactionFilter(),
        scope: PeriodScope.month,
      ),
    );
  }

  void _onScopeSelected(
    TransactionsScopeSelected event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(scope: event.scope));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  Future<void> _load(
    Emitter<TransactionsState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(state.copyWith(status: TransactionsStatus.loading));
    }
    try {
      final results = await Future.wait<Object?>([
        _transactions.transactions(),
        _accounts.accounts(),
        _categories.categories(),
        _transactions.paymentMode(),
      ]);
      emit(
        state.copyWith(
          status: TransactionsStatus.ready,
          transactions: results[0]! as List<Transaction>,
          accounts: results[1]! as List<Account>,
          categories: results[2]! as List<TransactionCategory>,
          twoPayments: results[3] == PaymentMode.twoPayments,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: TransactionsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(status: TransactionsStatus.failure));
    }
  }
}
