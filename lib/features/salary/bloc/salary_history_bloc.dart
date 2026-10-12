import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/salary/domain/salary_history_entry.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';

part 'salary_history_event.dart';
part 'salary_history_state.dart';

/// The Salary history screen: the saved months, and which month a new one
/// starts with.
class SalaryHistoryBloc extends Bloc<SalaryHistoryEvent, SalaryHistoryState> {
  new({required this._repository, required DateTime Function() now})
    : _currentMonth = YearMonth.fromDate(now()),
      super(SalaryHistoryState(newMonth: YearMonth.fromDate(now()))) {
    _changes = _repository.changes.listen(
      (_) => add(const SalaryHistoryDataChanged()),
    );
    on<SalaryHistoryStarted>(_onStarted, transformer: droppable());
    on<SalaryHistoryRefreshed>(_onRefreshed, transformer: restartable());
    on<SalaryHistoryRetried>(_onRetried, transformer: droppable());
    on<SalaryHistoryDataChanged>(_onDataChanged, transformer: restartable());
  }

  final SalaryRepository _repository;

  /// The month of today: no later month is started.
  final YearMonth _currentMonth;

  late final StreamSubscription<void> _changes;

  Future<void> _onStarted(
    SalaryHistoryStarted event,
    Emitter<SalaryHistoryState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onRefreshed(
    SalaryHistoryRefreshed event,
    Emitter<SalaryHistoryState> emit,
  ) {
    return _load(emit, showLoading: false);
  }

  Future<void> _onRetried(
    SalaryHistoryRetried event,
    Emitter<SalaryHistoryState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onDataChanged(
    SalaryHistoryDataChanged event,
    Emitter<SalaryHistoryState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  Future<void> _load(
    Emitter<SalaryHistoryState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(state.copyWith(status: SalaryHistoryStatus.loading));
    }
    try {
      final months = await _repository.savedMonths();
      final entries = [
        for (final month in months) ?SalaryHistoryEntry.tryFrom(month),
      ];
      emit(
        state.copyWith(
          status: SalaryHistoryStatus.ready,
          entries: entries,
          newMonth: _firstFreeMonth({
            for (final entry in entries) entry.month.month,
          }),
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: SalaryHistoryStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: SalaryHistoryStatus.failure));
    }
  }

  /// The latest month, counting back from the month of today, that is not in
  /// [saved].
  YearMonth _firstFreeMonth(Set<YearMonth> saved) {
    var month = _currentMonth;
    while (saved.contains(month)) {
      month = month.previous;
    }
    return month;
  }
}
