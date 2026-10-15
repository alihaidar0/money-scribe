import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';

/// The five lines of money a month, or one part of it, is made of. Income is
/// positive, spending is negative, and everything else follows from the five.
final class OverviewFigures extends Equatable {
  const new({
    required this.salary,
    required this.recurringIncome,
    required this.fixedCosts,
    required this.purchases,
    required this.debtMovements,
  });

  /// Pay received for the period (positive).
  final Money salary;

  /// Recurring income, such as a scholarship (positive).
  final Money recurringIncome;

  /// Recurring costs, such as rent and services (negative).
  final Money fixedCosts;

  /// What was bought (negative).
  final Money purchases;

  /// Money that moved because of debts: repayments received are positive,
  /// repayments made negative.
  final Money debtMovements;

  Money get income => salary + recurringIncome;

  Money get spent => fixedCosts + purchases;

  /// What is left: income, spending and debt movements together.
  Money get balance => income + spent + debtMovements;

  @override
  List<Object> get props => [
    salary,
    recurringIncome,
    fixedCosts,
    purchases,
    debtMovements,
  ];
}
