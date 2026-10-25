import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/salary/domain/salary_calculator.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// A saved month with what it comes to, for the list of saved months.
final class SalaryHistoryEntry extends Equatable {
  const new({required this.month, required this.result});

  /// The entry of [month]: with the figures the server calculated when it
  /// gave them, otherwise calculated here. `null` when its numbers cannot be
  /// calculated, which a saved month never should.
  static SalaryHistoryEntry? tryFrom(SalaryMonth month) {
    final figures = month.figures;
    if (figures != null) {
      return SalaryHistoryEntry(month: month, result: figures.result);
    }
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
