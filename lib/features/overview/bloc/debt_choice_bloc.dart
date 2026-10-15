import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';

part 'debt_choice_event.dart';
part 'debt_choice_state.dart';

/// The Choose a debt sheet: the debts a repayment can be added to.
class DebtChoiceBloc extends Bloc<DebtChoiceEvent, DebtChoiceState> {
  new({required this._repository}) : super(const DebtChoiceState()) {
    on<DebtChoiceStarted>(_onStarted, transformer: droppable());
  }

  final OverviewRepository _repository;

  Future<void> _onStarted(
    DebtChoiceStarted event,
    Emitter<DebtChoiceState> emit,
  ) async {
    emit(const DebtChoiceState());
    try {
      final debts = await _repository.debtsToRepay();
      emit(DebtChoiceState(status: DebtChoiceStatus.ready, debts: debts));
    } on NoConnectionException {
      emit(const DebtChoiceState(status: DebtChoiceStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(const DebtChoiceState(status: DebtChoiceStatus.failure));
    }
  }
}
