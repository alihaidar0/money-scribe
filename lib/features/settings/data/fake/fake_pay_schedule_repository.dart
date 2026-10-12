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
  Future<PaySchedule> load() async {
    await _demo.simulateRequest();
    // The demo panel can change how the account is paid at any time.
    return (saved ?? const PaySchedule()).copyWith(
      mode: _demo.settings.paymentMode,
    );
  }

  @override
  Future<void> save(PaySchedule schedule) async {
    await _demo.simulateRequest();
    saved = schedule;
    // The fake server keeps one account: its payment mode shapes the other
    // fake screens, such as the Overview.
    _demo.update(_demo.settings.copyWith(paymentMode: schedule.mode));
  }
}
