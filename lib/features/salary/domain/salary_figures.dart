import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// What is left of each payment of a month once its fixed items are counted,
/// as the server calculated it. A balance can be negative.
final class SalaryBalances extends Equatable {
  const new({required this.first, required this.month, this.second});

  /// The balance of the first payment (the whole month's, with one payment).
  final Money first;

  /// The balance of the second payment, or `null` with one payment.
  final Money? second;

  /// The balance of the whole month.
  final Money month;

  @override
  List<Object?> get props => [first, second, month];
}

/// What the server calculated for a saved month: the lines of its salary, the
/// payments among them, and the balances the fixed items leave. The app shows
/// these for a month as it is saved, and calculates only what is being typed.
final class SalaryFigures extends Equatable {
  const new({required this.result, required this.balances});

  final SalaryResult result;
  final SalaryBalances balances;

  @override
  List<Object> get props => [result, balances];
}
