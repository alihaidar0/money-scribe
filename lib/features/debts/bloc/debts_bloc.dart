import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

part 'debts_event.dart';
part 'debts_state.dart';

/// The Debts screen: every debt, filtered by lent or borrowed, with what is
/// owed to the person and what they owe.
class DebtsBloc extends Bloc<DebtsEvent, DebtsState> {
  new({required this._repository, required DateTime Function() now})
    : _now = now,
      super(DebtsState(today: _day(now()))) {
    _changes = _repository.changes.listen((_) => add(const DebtsDataChanged()));
    on<DebtsStarted>(_onStarted, transformer: droppable());
    on<DebtsRetried>(_onRetried, transformer: droppable());
    on<DebtsDataChanged>(_onDataChanged, transformer: restartable());
    on<DebtsRefreshed>(_onRefreshed, transformer: restartable());
    on<DebtsFilterSelected>(_onFilterSelected, transformer: sequential());
    on<DebtSelected>(_onSelected, transformer: sequential());
    on<DebtDeleteConfirmed>(_onDeleteConfirmed, transformer: droppable());
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  final DebtsRepository _repository;
  final DateTime Function() _now;

  late final StreamSubscription<void> _changes;

  Future<void> _onStarted(DebtsStarted event, Emitter<DebtsState> emit) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onRetried(DebtsRetried event, Emitter<DebtsState> emit) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onDataChanged(
    DebtsDataChanged event,
    Emitter<DebtsState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onRefreshed(DebtsRefreshed event, Emitter<DebtsState> emit) {
    return _load(emit, showLoading: false);
  }

  void _onFilterSelected(DebtsFilterSelected event, Emitter<DebtsState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onSelected(DebtSelected event, Emitter<DebtsState> emit) {
    emit(state.copyWith(selectedId: event.id));
  }

  Future<void> _onDeleteConfirmed(
    DebtDeleteConfirmed event,
    Emitter<DebtsState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteStatus: DebtsDeleteStatus.deleting,
        deletingId: event.id,
      ),
    );
    try {
      await _repository.delete(event.id);
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      if (error is! NoConnectionException) addError(error, stackTrace);
      emit(state.copyWith(deleteStatus: DebtsDeleteStatus.failed));
      return;
    }
    emit(state.copyWith(deleteStatus: DebtsDeleteStatus.idle));
    await _load(emit, showLoading: false);
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  Future<void> _load(
    Emitter<DebtsState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) emit(state.copyWith(status: DebtsStatus.loading));
    try {
      final debts = await _repository.debts();
      emit(
        state.copyWith(
          status: DebtsStatus.ready,
          debts: debts,
          today: _day(_now()),
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: DebtsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(status: DebtsStatus.failure));
    }
  }
}
