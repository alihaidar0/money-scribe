part of 'pay_schedule_bloc.dart';

sealed class PayScheduleEvent extends Equatable {
  const new();
}

/// The Pay schedule screen of the Settings opened: load the schedule that is
/// saved. The first-start question never sends it: it begins with the default.
final class PayScheduleStarted extends PayScheduleEvent {
  const new();

  @override
  List<Object> get props => [];
}

/// The user chose one payment or two a month.
final class PaymentModeSelected extends PayScheduleEvent {
  const new(this.mode);

  final PaymentMode mode;

  @override
  List<Object> get props => [mode];
}

/// The user changed the day the first payment is paid.
final class FirstPayDayChanged extends PayScheduleEvent {
  const new(this.day);

  final int day;

  @override
  List<Object> get props => [day];
}

/// The user changed the day the second payment is paid.
final class SecondPayDayChanged extends PayScheduleEvent {
  const new(this.day);

  final int day;

  @override
  List<Object> get props => [day];
}

/// The user pressed Continue.
final class PayScheduleConfirmed extends PayScheduleEvent {
  const new();

  @override
  List<Object> get props => [];
}

/// The user turned the reminder on the pay days on or off.
final class RemindOnPayDaysChanged extends PayScheduleEvent {
  const new({required this.remind});

  final bool remind;

  @override
  List<Object> get props => [remind];
}
