import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

part 'debt_form_event.dart';
part 'debt_form_state.dart';

/// The Add debt and Edit debt form. Without an id it starts a new debt that
/// begins today; with one it loads that debt to be changed.
class DebtFormBloc extends Bloc<DebtFormEvent, DebtFormState> {
  new({required this._repository, required DateTime Function() now, String? id})
    : _today = _day(now()),
      super(
        DebtFormState(
          debtId: id,
          values: DebtFormValues(startDate: _day(now())),
          baseline: DebtFormValues(startDate: _day(now())),
        ),
      ) {
    on<DebtFormStarted>(_onStarted, transformer: droppable());
    on<DebtFormRetried>(_onStarted, transformer: droppable());
    on<DebtDirectionSelected>(_onDirectionSelected, transformer: sequential());
    on<DebtPersonChanged>(_onPersonChanged, transformer: sequential());
    on<DebtAmountChanged>(_onAmountChanged, transformer: sequential());
    on<DebtStartDateChosen>(_onStartDateChosen, transformer: sequential());
    on<DebtDueDateChosen>(_onDueDateChosen, transformer: sequential());
    on<DebtDueDateCleared>(_onDueDateCleared, transformer: sequential());
    on<DebtNoteChanged>(_onNoteChanged, transformer: sequential());
    on<DebtSaveRequested>(_onSaveRequested, transformer: droppable());
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  final DebtsRepository _repository;

  /// The day of today, which a new debt starts on.
  final DateTime _today;

  Future<void> _onStarted(
    DebtFormEvent event,
    Emitter<DebtFormState> emit,
  ) async {
    final id = state.debtId;
    if (id == null) {
      emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          values: DebtFormValues(startDate: _today),
          baseline: DebtFormValues(startDate: _today),
        ),
      );
      return;
    }

    emit(state.copyWith(status: DebtFormStatus.loading));
    try {
      final debt = await _repository.debt(id);
      if (debt == null) {
        emit(state.copyWith(status: DebtFormStatus.notFound));
        return;
      }
      final values = DebtFormValues(
        direction: debt.direction,
        person: debt.person,
        amountText: debt.amount.toDecimalString(),
        startDate: debt.startDate,
        dueDate: debt.dueDate,
        note: debt.note,
      );
      emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          values: values,
          baseline: values,
          repaid: debt.repaid,
          currency: debt.amount.currency,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: DebtFormStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: DebtFormStatus.failure));
    }
  }

  void _edit(Emitter<DebtFormState> emit, DebtFormValues values) {
    emit(
      state.copyWith(
        values: values,
        // Edited since it was last saved.
        saveStatus: DebtFormSaveStatus.idle,
      ),
    );
  }

  void _onDirectionSelected(
    DebtDirectionSelected event,
    Emitter<DebtFormState> emit,
  ) {
    _edit(emit, state.values.copyWith(direction: event.direction));
  }

  void _onPersonChanged(DebtPersonChanged event, Emitter<DebtFormState> emit) {
    _edit(emit, state.values.copyWith(person: event.text));
  }

  void _onAmountChanged(DebtAmountChanged event, Emitter<DebtFormState> emit) {
    _edit(emit, state.values.copyWith(amountText: event.text));
  }

  void _onStartDateChosen(
    DebtStartDateChosen event,
    Emitter<DebtFormState> emit,
  ) {
    _edit(emit, state.values.copyWith(startDate: _day(event.date)));
  }

  void _onDueDateChosen(DebtDueDateChosen event, Emitter<DebtFormState> emit) {
    _edit(emit, state.values.copyWith(dueDate: _day(event.date)));
  }

  void _onDueDateCleared(
    DebtDueDateCleared event,
    Emitter<DebtFormState> emit,
  ) {
    _edit(emit, state.values.copyWith(clearDueDate: true));
  }

  void _onNoteChanged(DebtNoteChanged event, Emitter<DebtFormState> emit) {
    _edit(emit, state.values.copyWith(note: event.text));
  }

  Future<void> _onSaveRequested(
    DebtSaveRequested event,
    Emitter<DebtFormState> emit,
  ) async {
    final draft = state.canSave ? state.draft : null;
    if (draft == null) return;

    // What is sent is what becomes the saved debt, even if the person types on
    // while the server answers.
    final sent = state.values;
    emit(state.copyWith(saveStatus: DebtFormSaveStatus.saving));
    try {
      final id = state.debtId;
      if (id == null) {
        await _repository.add(draft);
      } else {
        await _repository.update(id, draft);
      }
      emit(
        state.copyWith(saveStatus: DebtFormSaveStatus.saved, baseline: sent),
      );
    } on NoConnectionException {
      emit(state.copyWith(saveStatus: DebtFormSaveStatus.failed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(saveStatus: DebtFormSaveStatus.failed));
    }
  }
}
