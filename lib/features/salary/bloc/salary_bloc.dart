import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/salary_calculator.dart';
import 'package:money_scribe/features/salary/domain/salary_form.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

part 'salary_event.dart';
part 'salary_state.dart';

/// The Salary screen: the salary of a month as it is typed, what it comes to,
/// and saving it.
class SalaryBloc extends Bloc<SalaryEvent, SalaryState> {
  new({required this._repository, required DateTime Function() now})
    : _currentMonth = YearMonth.fromDate(now()),
      super(SalaryState(month: YearMonth.fromDate(now()))) {
    _changes = _repository.changes.listen(
      (_) => add(const SalaryDataChanged()),
    );
    on<SalaryStarted>(_onStarted, transformer: droppable());
    // Choosing another month before the answer comes starts over from it.
    on<SalaryMonthSelected>(_onMonthSelected, transformer: restartable());
    on<SalaryFieldChanged>(_onFieldChanged, transformer: sequential());
    on<SalaryPaymentModeSelected>(_onModeSelected, transformer: sequential());
    on<SalarySaveRequested>(_onSaveRequested, transformer: droppable());
    on<SalaryDeleteRequested>(_onDeleteRequested, transformer: droppable());
    on<SalaryRetried>(_onRetried, transformer: droppable());
    on<SalaryDataChanged>(_onDataChanged, transformer: restartable());
  }

  final SalaryRepository _repository;

  /// The month of today: no later month is shown.
  final YearMonth _currentMonth;

  late final StreamSubscription<void> _changes;

  Future<void> _onStarted(SalaryStarted event, Emitter<SalaryState> emit) {
    return _load(event.month ?? state.month, emit);
  }

  Future<void> _onMonthSelected(
    SalaryMonthSelected event,
    Emitter<SalaryState> emit,
  ) {
    if (event.month > _currentMonth) return Future.value();
    return _load(event.month, emit);
  }

  void _onFieldChanged(SalaryFieldChanged event, Emitter<SalaryState> emit) {
    emit(
      state.copyWith(
        form: state.form.withField(event.field, event.value),
        saveStatus: _afterEdit(state.saveStatus),
      ),
    );
  }

  void _onModeSelected(
    SalaryPaymentModeSelected event,
    Emitter<SalaryState> emit,
  ) {
    if (event.mode == state.form.paymentMode) return;
    emit(
      state.copyWith(
        form: state.form.withPaymentMode(event.mode),
        saveStatus: _afterEdit(state.saveStatus),
      ),
    );
  }

  Future<void> _onSaveRequested(
    SalarySaveRequested event,
    Emitter<SalaryState> emit,
  ) async {
    final month = state.canSave
        ? state.form.toMonth(
            state.month,
            version: state.isSaved ? state.version : null,
          )
        : null;
    if (month == null) return;

    // What is sent is what becomes the saved month, even if the person types
    // on while the server answers.
    final sent = state.form;
    emit(state.copyWith(saveStatus: SalarySaveStatus.saving));
    try {
      final saved = await _repository.save(month);
      emit(
        state.copyWith(
          saveStatus: SalarySaveStatus.saved,
          isSaved: true,
          version: saved.version,
          baseline: sent,
        ),
      );
    } on StaleRecordException {
      emit(state.copyWith(saveStatus: SalarySaveStatus.stale));
    } on NoConnectionException {
      emit(state.copyWith(saveStatus: SalarySaveStatus.failed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(saveStatus: SalarySaveStatus.failed));
    }
  }

  Future<void> _onDeleteRequested(
    SalaryDeleteRequested event,
    Emitter<SalaryState> emit,
  ) async {
    if (!state.isSaved) return;

    emit(state.copyWith(deleteStatus: SalaryDeleteStatus.deleting));
    try {
      await _repository.delete(state.month, version: state.version);
      emit(state.copyWith(deleteStatus: SalaryDeleteStatus.deleted));
    } on StaleRecordException {
      emit(state.copyWith(deleteStatus: SalaryDeleteStatus.stale));
    } on NoConnectionException {
      emit(state.copyWith(deleteStatus: SalaryDeleteStatus.failed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(deleteStatus: SalaryDeleteStatus.failed));
    }
  }

  Future<void> _onRetried(SalaryRetried event, Emitter<SalaryState> emit) {
    return _load(state.month, emit);
  }

  Future<void> _onDataChanged(
    SalaryDataChanged event,
    Emitter<SalaryState> emit,
  ) {
    return _load(state.month, emit);
  }

  /// What an edit makes of the save status: a result that was shown is
  /// forgotten, but a save in progress goes on.
  SalarySaveStatus _afterEdit(SalarySaveStatus status) {
    return status == SalarySaveStatus.saving ? status : SalarySaveStatus.idle;
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    await super.close();
  }

  Future<void> _load(YearMonth month, Emitter<SalaryState> emit) async {
    emit(
      state.copyWith(
        status: SalaryStatus.loading,
        month: month,
        saveStatus: SalarySaveStatus.idle,
        deleteStatus: SalaryDeleteStatus.idle,
      ),
    );
    try {
      final saved = await _repository.month(month);
      final form = saved == null
          ? SalaryForm.empty(await _repository.defaults(month))
          : SalaryForm.fromMonth(saved);
      emit(
        state.copyWith(
          status: SalaryStatus.ready,
          form: form,
          baseline: form,
          isSaved: saved != null,
          version: saved?.version ?? 0,
          formVersion: state.formVersion + 1,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: SalaryStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: SalaryStatus.failure));
    }
  }
}
