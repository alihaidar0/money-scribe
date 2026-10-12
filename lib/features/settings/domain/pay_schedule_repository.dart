import 'package:money_scribe/features/settings/domain/pay_schedule.dart';

/// Where the pay schedule is kept: on the server. Can throw a `DataException`
/// when the server cannot be reached or fails.
abstract interface class PayScheduleRepository {
  /// How the salary is paid now.
  Future<PaySchedule> load();

  /// Saves how the salary is paid.
  Future<void> save(PaySchedule schedule);
}
