import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';

part 'pay_schedule_event.dart';
part 'pay_schedule_state.dart';

/// Choosing how the salary is paid: one payment or two, and the pay days.
class PayScheduleBloc extends Bloc<PayScheduleEvent, PayScheduleState> {
  new({required this._repository}) : super(const PayScheduleState()) {
    on<PaymentModeSelected>(_onModeSelected, transformer: sequential());
    on<FirstPayDayChanged>(_onFirstPayDayChanged, transformer: sequential());
    on<SecondPayDayChanged>(_onSecondPayDayChanged, transformer: sequential());
    // A second press while the first is being saved is ignored.
    on<PayScheduleConfirmed>(_onConfirmed, transformer: droppable());
  }

  final PayScheduleRepository _repository;

  void _onModeSelected(
    PaymentModeSelected event,
    Emitter<PayScheduleState> emit,
  ) {
    emit(_edited(state.schedule.copyWith(mode: event.mode)));
  }

  void _onFirstPayDayChanged(
    FirstPayDayChanged event,
    Emitter<PayScheduleState> emit,
  ) {
    emit(_edited(state.schedule.copyWith(firstPayDay: _inMonth(event.day))));
  }

  void _onSecondPayDayChanged(
    SecondPayDayChanged event,
    Emitter<PayScheduleState> emit,
  ) {
    emit(_edited(state.schedule.copyWith(secondPayDay: _inMonth(event.day))));
  }

  Future<void> _onConfirmed(
    PayScheduleConfirmed event,
    Emitter<PayScheduleState> emit,
  ) async {
    emit(state.copyWith(status: PayScheduleStatus.saving));
    try {
      await _repository.save(state.schedule);
      emit(state.copyWith(status: PayScheduleStatus.saved));
    } on NoConnectionException {
      emit(state.copyWith(status: PayScheduleStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: PayScheduleStatus.failure));
    }
  }

  PayScheduleState _edited(PaySchedule schedule) {
    return PayScheduleState(schedule: schedule);
  }

  int _inMonth(int day) {
    return day.clamp(PaySchedule.firstDayOfMonth, PaySchedule.lastDayOfMonth);
  }
}
