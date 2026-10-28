import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';
import 'package:money_scribe/features/reports/domain/reports_repository.dart';

part 'reports_event.dart';
part 'reports_state.dart';

/// The Reports screen: the spending by category, a month against the month
/// before, and where the debts stand. It shows one month, and for a month paid
/// in two payments the whole month or one part.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  new({required this._repository, required DateTime Function() now})
    : super(ReportsState(month: YearMonth.fromDate(now()))) {
    _changes = _repository.changes.listen(
      (change) => add(ReportsDataChanged(silent: change == DataChange.saved)),
    );
    on<ReportsStarted>(_onStarted, transformer: droppable());
    on<ReportsRetried>(_onRetried, transformer: droppable());
    on<ReportsDataChanged>(_onDataChanged, transformer: restartable());
    on<ReportsRefreshed>(_onRefreshed, transformer: restartable());
    // Choosing another month before the answer comes starts over from it.
    on<ReportsMonthSelected>(_onMonthSelected, transformer: restartable());
    on<ReportsCompareMonthSelected>(
      _onCompareMonthSelected,
      transformer: restartable(),
    );
    on<ReportsViewSelected>(_onViewSelected, transformer: sequential());
    on<ReportsScopeSelected>(_onScopeSelected, transformer: sequential());
  }

  final ReportsRepository _repository;

  late final StreamSubscription<DataChange> _changes;

  Future<void> _onStarted(ReportsStarted event, Emitter<ReportsState> emit) {
    return _load(state.month, emit, comparedWith: state.comparedWith);
  }

  Future<void> _onRetried(ReportsRetried event, Emitter<ReportsState> emit) {
    return _load(state.month, emit, comparedWith: state.comparedWith);
  }

  Future<void> _onDataChanged(
    ReportsDataChanged event,
    Emitter<ReportsState> emit,
  ) {
    return _load(
      state.month,
      emit,
      comparedWith: state.comparedWith,
      silent: event.silent,
    );
  }

  Future<void> _onRefreshed(
    ReportsRefreshed event,
    Emitter<ReportsState> emit,
  ) async {
    try {
      await _load(
        state.month,
        emit,
        comparedWith: state.comparedWith,
        silent: true,
      );
    } finally {
      event.done?.complete();
    }
  }

  Future<void> _onMonthSelected(
    ReportsMonthSelected event,
    Emitter<ReportsState> emit,
  ) {
    if (event.month == state.month && state.status == ReportsStatus.ready) {
      return Future.value();
    }
    // A new month is compared with the month before it again.
    return _load(event.month, emit);
  }

  Future<void> _onCompareMonthSelected(
    ReportsCompareMonthSelected event,
    Emitter<ReportsState> emit,
  ) {
    if (event.month == state.compareMonth &&
        state.status == ReportsStatus.ready) {
      return Future.value();
    }
    return _load(state.month, emit, comparedWith: event.month);
  }

  void _onViewSelected(ReportsViewSelected event, Emitter<ReportsState> emit) {
    emit(state.copyWith(view: event.view));
  }

  void _onScopeSelected(
    ReportsScopeSelected event,
    Emitter<ReportsState> emit,
  ) {
    emit(state.copyWith(scope: event.scope));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  /// Loads [month]. A [silent] load of a screen that already shows a report
  /// keeps showing it until the new one comes, and keeps it when it does not.
  Future<void> _load(
    YearMonth month,
    Emitter<ReportsState> emit, {
    YearMonth? comparedWith,
    bool silent = false,
  }) async {
    final compareMonth = comparedWith ?? month.previous;
    final keepShown =
        silent &&
        (state.status == ReportsStatus.ready ||
            state.status == ReportsStatus.empty);
    emit(
      state.copyWith(
        status: keepShown ? state.status : ReportsStatus.loading,
        month: month,
      ),
    );
    try {
      final results = await Future.wait<Object?>([
        _repository.month(month),
        _repository.month(compareMonth),
        _repository.debts(),
      ]);
      final report = results[0] as MonthReport?;
      if (report == null) {
        // Nothing to report for the month, but the debts do not depend on it.
        emit(
          ReportsState(
            status: ReportsStatus.empty,
            month: month,
            view: state.view,
            scope: state.scope,
            comparedWith: comparedWith,
            debts: results[2]! as DebtsReport,
          ),
        );
        return;
      }
      // Built whole, not copied: a month with nothing to compare with must not
      // keep the comparison of the one shown earlier.
      emit(
        ReportsState(
          status: ReportsStatus.ready,
          month: month,
          view: state.view,
          scope: state.scope,
          comparedWith: comparedWith,
          report: report,
          previousReport: results[1] as MonthReport?,
          debts: results[2]! as DebtsReport,
        ),
      );
    } on NoConnectionException {
      if (keepShown) return;
      emit(state.copyWith(status: ReportsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      if (keepShown) return;
      emit(state.copyWith(status: ReportsStatus.failure));
    }
  }
}
