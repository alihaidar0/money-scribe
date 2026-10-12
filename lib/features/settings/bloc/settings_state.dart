part of 'settings_bloc.dart';

enum SettingsStatus {
  /// The settings are being loaded.
  loading,

  /// The settings are shown.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class SettingsState extends Equatable {
  const new({
    this.status = SettingsStatus.loading,
    this.schedule = const PaySchedule(),
    this.currency = Currency.rub,
    this.failedAction,
  });

  final SettingsStatus status;

  /// How the salary is paid.
  final PaySchedule schedule;

  /// The currency new amounts are in.
  final Currency currency;

  /// The last change that the server did not accept, so the screen can offer
  /// to try it again. `null` once something else was done.
  final SettingsEvent? failedAction;

  SettingsState copyWith({
    SettingsStatus? status,
    PaySchedule? schedule,
    Currency? currency,
    SettingsEvent? failedAction,
    bool clearFailedAction = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      schedule: schedule ?? this.schedule,
      currency: currency ?? this.currency,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
    );
  }

  @override
  List<Object?> get props => [status, schedule, currency, failedAction];
}
