import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/salary/domain/salary_calculator.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// A saved month with what it comes to, for the list of saved months.
final class SalaryHistoryEntry extends Equatable {
  const new({required this.month, required this.result});

  /// The entry of [month], or `null` when its numbers cannot be calculated,
  /// which a saved month never should.
  static SalaryHistoryEntry? tryFrom(SalaryMonth month) {
    return switch (SalaryCalculator.calculate(month.inputs)) {
      SalaryComputed(:final result) => SalaryHistoryEntry(
        month: month,
        result: result,
      ),
      SalaryRejected() => null,
    };
  }

  final SalaryMonth month;
  final SalaryResult result;

  @override
  List<Object> get props => [month, result];
}
