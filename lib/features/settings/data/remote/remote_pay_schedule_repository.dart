import 'package:money_scribe/core/api/export.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/settings/data/remote/remote_settings.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule_repository.dart';

/// The pay schedule on the server: the real [PayScheduleRepository].
class RemotePayScheduleRepository implements PayScheduleRepository {
  new(this._settings);

  final RemoteSettings _settings;

  @override
  Future<PaySchedule> load() async {
    final settings = await _settings.read();
    return PaySchedule(
      mode: settings.paymentMode == PaymentModeEnum.twoPayments
          ? PaymentMode.twoPayments
          : PaymentMode.onePayment,
      firstPayDay: settings.firstPayDay,
      secondPayDay: settings.secondPayDay,
      remindOnPayDays: settings.remindOnPayDays,
    );
  }

  @override
  Future<void> save(PaySchedule schedule) async {
    await _settings.update(
      paymentMode: switch (schedule.mode) {
        PaymentMode.onePayment => PaymentModeEnum.onePayment,
        PaymentMode.twoPayments => PaymentModeEnum.twoPayments,
      },
      firstPayDay: schedule.firstPayDay,
      secondPayDay: schedule.secondPayDay,
      remindOnPayDays: schedule.remindOnPayDays,
    );
  }
}
