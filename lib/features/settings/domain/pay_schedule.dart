import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// When the salary is paid: one payment or two, and on which days.
final class PaySchedule extends Equatable {
  const new({
    this.mode = PaymentMode.onePayment,
    this.firstPayDay = 20,
    this.secondPayDay = 5,
    this.remindOnPayDays = false,
  });

  /// The first and the last day of the month a pay day can be set to, so it
  /// exists in every month.
  static const firstDayOfMonth = 1;
  static const lastDayOfMonth = 28;

  final PaymentMode mode;

  /// The day of the month the first payment is paid.
  final int firstPayDay;

  /// The day of the next month the second payment is paid. It is before
  /// [firstPayDay].
  final int secondPayDay;

  /// Whether the person is reminded on the pay days.
  final bool remindOnPayDays;

  /// The earliest the first pay day can be: the second one is before it.
  int get earliestFirstPayDay => min(secondPayDay + 1, lastDayOfMonth);

  /// The latest the second pay day can be: it is before the first one.
  int get latestSecondPayDay => max(firstPayDay - 1, firstDayOfMonth);

  /// How the schedule cuts a month into parts.
  PayCycle get cycle => switch (mode) {
    PaymentMode.onePayment => const PayCycle.onePayment(),
    PaymentMode.twoPayments => partsCycle,
  };

  /// How a month paid in two payments is cut by these pay days, whatever the
  /// schedule says for new months: a month saved in two payments is cut by the
  /// pay days of the settings.
  PayCycle get partsCycle => PayCycle.twoPayments(
    firstPayDay: firstPayDay,
    secondPayDay: secondPayDay,
  );

  PaySchedule copyWith({
    PaymentMode? mode,
    int? firstPayDay,
    int? secondPayDay,
    bool? remindOnPayDays,
  }) {
    return PaySchedule(
      mode: mode ?? this.mode,
      firstPayDay: firstPayDay ?? this.firstPayDay,
      secondPayDay: secondPayDay ?? this.secondPayDay,
      remindOnPayDays: remindOnPayDays ?? this.remindOnPayDays,
    );
  }

  @override
  List<Object> get props => [mode, firstPayDay, secondPayDay, remindOnPayDays];
}
