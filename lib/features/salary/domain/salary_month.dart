import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';

/// A month's salary as it is saved: what it is calculated from, and the days
/// it is paid on. A saved month keeps its own schedule, so correcting an old
/// month never changes how a new one is paid.
final class SalaryMonth extends Equatable {
  const new({
    required this.month,
    required this.inputs,
    required this.firstPayDay,
    required this.secondPayDay,
  });

  final YearMonth month;
  final SalaryInputs inputs;

  /// The day of [month] the first payment (the 1st-15th) is paid. With one
  /// payment a month, the whole month is paid on this day.
  final int firstPayDay;

  /// The day of the next month the second payment (the 16th-end) is paid.
  final int secondPayDay;

  @override
  List<Object> get props => [month, inputs, firstPayDay, secondPayDay];
}
