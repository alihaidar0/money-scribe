import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

part 'debt_details_event.dart';
part 'debt_details_state.dart';

/// The Debt details screen: one debt with its repayments, adding, changing
/// and deleting repayments, and deleting the debt. A change names the version
/// it was made from; one that was made on another device meanwhile is not
/// applied, the debt is read again and the screen says so.
class DebtDetailsBloc extends Bloc<DebtDetailsEvent, DebtDetailsState> {
  new({
    required this._repository,
    required String id,
    required DateTime Function() now,
  }) : _now = now,
       super(DebtDetailsState(debtId: id, today: _day(now()))) {
    _changes = _repository.changes.listen(
      (_) => add(const DebtDetailsDataChanged()),
    );
    on<DebtDetailsStarted>(_onStarted, transformer: droppable());
    on<DebtDetailsRetried>(_onRetried, transformer: droppable());
    on<DebtDetailsDataChanged>(_onDataChanged, transformer: restartable());
    on<DebtDetailsRefreshed>(_onRefreshed, transformer: restartable());
    on<RepaymentAdded>(_onRepaymentAdded, transformer: sequential());
    on<RepaymentChanged>(_onRepaymentChanged, transformer: sequential());
    on<RepaymentDeleted>(_onRepaymentDeleted, transformer: sequential());
    on<DebtDeleteRequested>(_onDeleteRequested, transformer: droppable());
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  final DebtsRepository _repository;
  final DateTime Function() _now;

  late final StreamSubscription<void> _changes;

  Future<void> _onStarted(
    DebtDetailsStarted event,
    Emitter<DebtDetailsState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onRetried(
    DebtDetailsRetried event,
    Emitter<DebtDetailsState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onDataChanged(
    DebtDetailsDataChanged event,
    Emitter<DebtDetailsState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onRefreshed(
    DebtDetailsRefreshed event,
    Emitter<DebtDetailsState> emit,
  ) {
    return _load(emit, showLoading: false);
  }

  Future<void> _onRepaymentAdded(
    RepaymentAdded event,
    Emitter<DebtDetailsState> emit,
  ) {
    return _run(
      event,
      emit,
      () => _repository.addRepayment(state.debtId, event.draft),
    );
  }

  Future<void> _onRepaymentChanged(
    RepaymentChanged event,
    Emitter<DebtDetailsState> emit,
  ) {
    return _run(
      event,
      emit,
      () => _repository.updateRepayment(
        state.debtId,
        event.id,
        event.draft,
        version: _repaymentOf(event.id).version,
      ),
    );
  }

  Future<void> _onRepaymentDeleted(
    RepaymentDeleted event,
    Emitter<DebtDetailsState> emit,
  ) {
    return _run(
      event,
      emit,
      () => _repository.deleteRepayment(
        state.debtId,
        event.id,
        version: _repaymentOf(event.id).version,
      ),
    );
  }

  Future<void> _onDeleteRequested(
    DebtDeleteRequested event,
    Emitter<DebtDetailsState> emit,
  ) async {
    final debt = state.debt;
    if (debt == null) return;

    emit(
      state.copyWith(
        deleteStatus: DebtDeleteStatus.deleting,
        clearNotices: true,
      ),
    );
    try {
      await _repository.delete(state.debtId, version: debt.version);
      emit(state.copyWith(deleteStatus: DebtDeleteStatus.deleted));
    } on StaleRecordException {
      emit(
        state.copyWith(
          deleteStatus: DebtDeleteStatus.idle,
          changedElsewhere: true,
        ),
      );
      await _load(emit, showLoading: false);
    } on NoConnectionException {
      emit(state.copyWith(deleteStatus: DebtDeleteStatus.failed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(deleteStatus: DebtDeleteStatus.failed));
    }
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  /// The repayment [id] of the debt being shown. One that is not there any
  /// more was deleted on another device, which is the same as a version that
  /// moved on.
  Repayment _repaymentOf(String id) {
    final debt = state.debt;
    if (debt != null) {
      for (final repayment in debt.repayments) {
        if (repayment.id == id) return repayment;
      }
    }
    throw const StaleRecordException();
  }

  /// Does [action], which changes a repayment on the server and answers with
  /// the debt. When the server does not accept it the debt stays as it was and
  /// [DebtDetailsState.failedAction] holds [event], so the screen can offer to
  /// try again. A refusal the person can act on is kept in
  /// [DebtDetailsState.refusal] instead, and a debt that changed on another
  /// device is read again.
  Future<void> _run(
    DebtDetailsEvent event,
    Emitter<DebtDetailsState> emit,
    Future<Debt> Function() action,
  ) async {
    emit(state.copyWith(clearFailedAction: true, clearNotices: true));
    try {
      emit(state.copyWith(debt: await action()));
    } on StaleRecordException {
      emit(state.copyWith(changedElsewhere: true));
      await _load(emit, showLoading: false);
    } on DebtRefusedException catch (refused) {
      emit(
        state.copyWith(
          refusal: refused.refusal,
          refusedRemaining: refused.remaining,
        ),
      );
      // Another device repaid some of it: show what is left now.
      if (refused.refusal == DebtRefusal.exceedsRemaining) {
        await _load(emit, showLoading: false);
      }
    } on NoConnectionException {
      emit(state.copyWith(failedAction: event));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(failedAction: event));
    }
  }

  Future<void> _load(
    Emitter<DebtDetailsState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(
        state.copyWith(
          status: DebtDetailsStatus.loading,
          clearFailedAction: true,
        ),
      );
    }
    try {
      final debt = await _repository.debt(state.debtId);
      if (debt == null) {
        emit(state.copyWith(status: DebtDetailsStatus.notFound));
        return;
      }
      emit(
        state.copyWith(
          status: DebtDetailsStatus.ready,
          debt: debt,
          today: _day(_now()),
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: DebtDetailsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(status: DebtDetailsStatus.failure));
    }
  }
}
