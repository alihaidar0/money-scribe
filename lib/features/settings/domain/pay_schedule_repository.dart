import 'package:money_scribe/features/settings/domain/pay_schedule.dart';

/// Where the pay schedule is kept: on the server. Can throw a `DataException`
/// when the server cannot be reached or fails.
abstract interface class PayScheduleRepository {
  Future<void> save(PaySchedule schedule);
}
