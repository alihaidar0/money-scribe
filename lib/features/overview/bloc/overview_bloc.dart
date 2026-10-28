import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';

part 'overview_event.dart';
part 'overview_state.dart';

/// The Overview screen: the figures of a month, which month is shown, and for
/// a month paid in two payments which part.
class OverviewBloc extends Bloc<OverviewEvent, OverviewState> {
  new({required this._repository, required DateTime Function() now})
    : _currentMonth = YearMonth.fromDate(now()),
      super(OverviewState(month: YearMonth.fromDate(now()))) {
    _changes = _repository.changes.listen(
      (change) => add(OverviewDataChanged(silent: change == DataChange.saved)),
    );
    on<OverviewStarted>(_onStarted, transformer: droppable());
    // Pressing the arrow again before the answer comes starts over from the
    // newest month.
    on<MonthStepped>(_onMonthStepped, transformer: restartable());
    on<PeriodScopeSelected>(_onScopeSelected, transformer: sequential());
    on<OverviewRetried>(_onRetried, transformer: droppable());
    on<OverviewDataChanged>(_onDataChanged, transformer: restartable());
    on<OverviewRefreshed>(_onRefreshed, transformer: restartable());
  }

  final OverviewRepository _repository;

  /// The month of today: the overview does not go past it.
  final YearMonth _currentMonth;

  late final StreamSubscription<DataChange> _changes;

  Future<void> _onStarted(OverviewStarted event, Emitter<OverviewState> emit) {
    return _load(state.month, emit);
  }

  Future<void> _onMonthStepped(
    MonthStepped event,
    Emitter<OverviewState> emit,
  ) {
    final month = event.forward ? state.month.next : state.month.previous;
    if (month > _currentMonth) return Future.value();
    return _load(month, emit);
  }

  void _onScopeSelected(
    PeriodScopeSelected event,
    Emitter<OverviewState> emit,
  ) {
    emit(state.copyWith(scope: event.scope));
  }

  Future<void> _onRetried(OverviewRetried event, Emitter<OverviewState> emit) {
    return _load(state.month, emit);
  }

  Future<void> _onDataChanged(
    OverviewDataChanged event,
    Emitter<OverviewState> emit,
  ) {
    return _load(state.month, emit, silent: event.silent);
  }

  Future<void> _onRefreshed(
    OverviewRefreshed event,
    Emitter<OverviewState> emit,
  ) async {
    try {
      await _load(state.month, emit, silent: true);
    } finally {
      event.done?.complete();
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  /// Loads [month]. A [silent] load of a screen that already shows a month
  /// keeps showing it until the new figures come, and keeps it when they do
  /// not: the person did not ask to look at a loading state or an error.
  Future<void> _load(
    YearMonth month,
    Emitter<OverviewState> emit, {
    bool silent = false,
  }) async {
    final keepShown =
        silent &&
        (state.overview != null || state.status == OverviewStatus.firstLaunch);
    emit(
      state.copyWith(
        status: keepShown ? state.status : OverviewStatus.loading,
        month: month,
        canStepForward: month < _currentMonth,
      ),
    );
    try {
      final overview = await _repository.month(month);
      emit(
        state.copyWith(
          status: overview == null
              ? OverviewStatus.firstLaunch
              : OverviewStatus.ready,
          overview: overview,
          clearOverview: overview == null,
        ),
      );
    } on NoConnectionException {
      if (keepShown) return;
      emit(state.copyWith(status: OverviewStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      if (keepShown) return;
      emit(state.copyWith(status: OverviewStatus.failure));
    }
  }
}
