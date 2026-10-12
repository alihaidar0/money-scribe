import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/features/settings/domain/default_currency_repository.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// The Settings screen: what is kept on the server and shown in the list, the
/// pay schedule and the default currency, and changing the default currency
/// and the reminder. The language and the theme are the other Blocs'.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  new({required this._paySchedule, required this._currency})
    : super(const SettingsState()) {
    on<SettingsStarted>(_onStarted, transformer: droppable());
    on<SettingsRetried>(_onStarted, transformer: droppable());
    on<SettingsRefreshed>(_onRefreshed, transformer: restartable());
    on<DefaultCurrencySelected>(_onCurrencySelected, transformer: sequential());
    on<PayDayReminderToggled>(_onReminderToggled, transformer: sequential());
  }

  final PayScheduleRepository _paySchedule;
  final DefaultCurrencyRepository _currency;

  Future<void> _onStarted(SettingsEvent event, Emitter<SettingsState> emit) {
    emit(state.copyWith(status: SettingsStatus.loading));
    return _load(emit);
  }

  Future<void> _onRefreshed(
    SettingsRefreshed event,
    Emitter<SettingsState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _load(Emitter<SettingsState> emit) async {
    try {
      final results = await Future.wait<Object>([
        _paySchedule.load(),
        _currency.load(),
      ]);
      emit(
        SettingsState(
          status: SettingsStatus.ready,
          schedule: results[0] as PaySchedule,
          currency: results[1] as Currency,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: SettingsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: SettingsStatus.failure));
    }
  }

  /// Shows the new currency at once and saves it; a refusal puts the old one
  /// back.
  Future<void> _onCurrencySelected(
    DefaultCurrencySelected event,
    Emitter<SettingsState> emit,
  ) async {
    final previous = state.currency;
    if (event.currency == previous) return;
    emit(state.copyWith(currency: event.currency, clearFailedAction: true));
    try {
      await _currency.save(event.currency);
    } on Exception catch (error, stackTrace) {
      if (error is! DataException) addError(error, stackTrace);
      emit(state.copyWith(currency: previous, failedAction: event));
    }
  }

  Future<void> _onReminderToggled(
    PayDayReminderToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final previous = state.schedule;
    if (event.remind == previous.remindOnPayDays) return;
    emit(
      state.copyWith(
        schedule: previous.copyWith(remindOnPayDays: event.remind),
        clearFailedAction: true,
      ),
    );
    try {
      await _paySchedule.save(state.schedule);
    } on Exception catch (error, stackTrace) {
      if (error is! DataException) addError(error, stackTrace);
      emit(state.copyWith(schedule: previous, failedAction: event));
    }
  }
}
