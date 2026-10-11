part of 'pay_schedule_bloc.dart';

enum PayScheduleStatus {
  /// The person is choosing.
  editing,

  /// The choice is being saved.
  saving,

  /// The choice was saved.
  saved,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class PayScheduleState extends Equatable {
  const new({
    this.schedule = const PaySchedule(),
    this.status = PayScheduleStatus.editing,
  });

  final PaySchedule schedule;
  final PayScheduleStatus status;

  PayScheduleState copyWith({PayScheduleStatus? status}) {
    return PayScheduleState(schedule: schedule, status: status ?? this.status);
  }

  @override
  List<Object> get props => [schedule, status];
}
