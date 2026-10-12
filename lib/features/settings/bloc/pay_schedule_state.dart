part of 'pay_schedule_bloc.dart';

enum PayScheduleStatus {
  /// The saved schedule is being loaded.
  loading,

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
    this.isLoaded = true,
  });

  final PaySchedule schedule;
  final PayScheduleStatus status;

  /// Whether [schedule] is the saved one (or the default of the first start).
  /// While it is not, a failure came from loading, and trying again loads.
  final bool isLoaded;

  PayScheduleState copyWith({PayScheduleStatus? status}) {
    return PayScheduleState(
      schedule: schedule,
      status: status ?? this.status,
      isLoaded: isLoaded,
    );
  }

  @override
  List<Object> get props => [schedule, status, isLoaded];
}
