import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';

/// A pay schedule that lives in memory, until the server exists.
class FakePayScheduleRepository implements PayScheduleRepository {
  new({required this._demo});

  final DemoController _demo;

  /// The last saved schedule, or `null` before the first one.
  PaySchedule? saved;

  @override
  Future<void> save(PaySchedule schedule) async {
    await _demo.simulateRequest();
    saved = schedule;
  }
}
