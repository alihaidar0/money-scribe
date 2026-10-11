import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// When the salary is paid: one payment or two, and on which days.
final class PaySchedule extends Equatable {
  const new({
    this.mode = PaymentMode.onePayment,
    this.firstPayDay = 20,
    this.secondPayDay = 5,
  });

  /// The first and the last day of the month a pay day can be set to, so it
  /// exists in every month.
  static const firstDayOfMonth = 1;
  static const lastDayOfMonth = 28;

  final PaymentMode mode;

  /// The day of the month the first payment (the 1st-15th) is paid.
  final int firstPayDay;

  /// The day of the next month the second payment (the 16th-end) is paid.
  final int secondPayDay;

  PaySchedule copyWith({
    PaymentMode? mode,
    int? firstPayDay,
    int? secondPayDay,
  }) {
    return PaySchedule(
      mode: mode ?? this.mode,
      firstPayDay: firstPayDay ?? this.firstPayDay,
      secondPayDay: secondPayDay ?? this.secondPayDay,
    );
  }

  @override
  List<Object> get props => [mode, firstPayDay, secondPayDay];
}
