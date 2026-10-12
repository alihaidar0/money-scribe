import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// How a new, empty month starts: the account's pay schedule.
final class SalaryDefaults extends Equatable {
  const new({
    this.paymentMode = PaymentMode.onePayment,
    this.firstPayDay = 20,
    this.secondPayDay = 5,
  });

  final PaymentMode paymentMode;
  final int firstPayDay;
  final int secondPayDay;

  @override
  List<Object> get props => [paymentMode, firstPayDay, secondPayDay];
}
