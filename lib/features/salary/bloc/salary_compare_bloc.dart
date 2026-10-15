import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_comparison.dart';
import 'package:money_scribe/features/salary/domain/salary_history_entry.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';

part 'salary_compare_event.dart';
part 'salary_compare_state.dart';

/// The Compare months screen: two months side by side, by default the two
/// newest saved ones, and the difference between them. A part also counts the
/// fixed items of each month.
class SalaryCompareBloc extends Bloc<SalaryCompareEvent, SalaryCompareState> {
  new({
    required this._repository,
    required this._fixedItems,
    required DateTime Function() now,
  }) : super(
         SalaryCompareState(
           left: YearMonth.fromDate(now()).previous,
           right: YearMonth.fromDate(now()),
         ),
       ) {
    _changes = [
      _repository.changes.listen((_) => add(const SalaryCompareDataChanged())),
      _fixedItems.changes.listen((_) => add(const SalaryCompareDataChanged())),
    ];
    on<SalaryCompareStarted>(_onStarted, transformer: droppable());
    on<SalaryCompareRetried>(_onRetried, transformer: droppable());
    on<SalaryCompareDataChanged>(_onDataChanged, transformer: restartable());
    on<SalaryCompareMonthChosen>(_onMonthChosen, transformer: sequential());
    on<SalaryCompareSwapped>(_onSwapped, transformer: sequential());
    on<SalaryCompareScopeSelected>(_onScopeSelected, transformer: sequential());
  }

  final SalaryRepository _repository;
  final FixedItemsRepository _fixedItems;

  late final List<StreamSubscription<void>> _changes;

  Future<void> _onStarted(
    SalaryCompareStarted event,
    Emitter<SalaryCompareState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onRetried(
    SalaryCompareRetried event,
    Emitter<SalaryCompareState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onDataChanged(
    SalaryCompareDataChanged event,
    Emitter<SalaryCompareState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onMonthChosen(
    SalaryCompareMonthChosen event,
    Emitter<SalaryCompareState> emit,
  ) async {
    final chosen = state.copyWith(monthsChosen: true);
    emit(switch (event.side) {
      CompareSide.left => chosen.copyWith(left: event.month),
      CompareSide.right => chosen.copyWith(right: event.month),
    });
    await _loadFixedItemsOf(event.month, emit);
  }

  void _onSwapped(
    SalaryCompareSwapped event,
    Emitter<SalaryCompareState> emit,
  ) {
    emit(state.copyWith(left: state.right, right: state.left));
  }

  void _onScopeSelected(
    SalaryCompareScopeSelected event,
    Emitter<SalaryCompareState> emit,
  ) {
    emit(state.copyWith(scope: event.scope));
  }

  @override
  Future<void> close() async {
    for (final subscription in _changes) {
      await subscription.cancel();
    }
    await super.close();
  }

  Future<void> _load(Emitter<SalaryCompareState> emit) async {
    emit(state.copyWith(status: SalaryCompareStatus.loading));
    try {
      final months = await _repository.savedMonths();
      final saved = [
        for (final month in months) ?SalaryHistoryEntry.tryFrom(month),
      ];
      final ready = _loaded(saved);
      final items = await _fixedItemsOf({ready.left, ready.right}, saved);
      emit(ready.copyWith(fixedItems: items));
    } on NoConnectionException {
      emit(state.copyWith(status: SalaryCompareStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: SalaryCompareStatus.failure));
    }
  }

  /// The fixed items of each of [months] that has a saved salary in [saved].
  Future<Map<YearMonth, List<FixedItem>>> _fixedItemsOf(
    Set<YearMonth> months,
    List<SalaryHistoryEntry> saved,
  ) async {
    final withSalary = [
      for (final month in months)
        if (saved.any((entry) => entry.month.month == month)) month,
    ];
    final items = await Future.wait([
      for (final month in withSalary) _fixedItems.items(month),
    ]);
    return {
      for (var i = 0; i < withSalary.length; i++) withSalary[i]: items[i],
    };
  }

  /// Loads the fixed items of [month] when it has a saved salary and they are
  /// not loaded yet.
  Future<void> _loadFixedItemsOf(
    YearMonth month,
    Emitter<SalaryCompareState> emit,
  ) async {
    if (state.fixedItems.containsKey(month) || state.entryOf(month) == null) {
      return;
    }
    try {
      final items = await _fixedItems.items(month);
      emit(state.copyWith(fixedItems: {...state.fixedItems, month: items}));
    } on NoConnectionException {
      emit(state.copyWith(status: SalaryCompareStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: SalaryCompareStatus.failure));
    }
  }

  /// The ready state with the [saved] months. Until the months were chosen, the
  /// two newest saved ones are compared, the earlier on the left; a month the
  /// account lacks is replaced by the one before the other.
  SalaryCompareState _loaded(List<SalaryHistoryEntry> saved) {
    final ready = state.copyWith(
      status: SalaryCompareStatus.ready,
      saved: saved,
    );
    if (state.monthsChosen) return ready;

    final right = saved.isEmpty ? state.right : saved[0].month.month;
    final left = saved.length < 2 ? right.previous : saved[1].month.month;
    return ready.copyWith(left: left, right: right, monthsChosen: true);
  }
}
