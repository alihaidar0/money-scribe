import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';

/// The lines of money a month, or one part of it, is made of. Income is
/// positive, spending is negative, and everything else follows from them.
final class OverviewFigures extends Equatable {
  const new({
    required this.salary,
    required this.recurringIncome,
    required this.otherIncome,
    required this.fixedCosts,
    required this.purchases,
    required this.debtMovements,
    this.reportedBalance,
  });

  /// Pay received for the period (positive).
  final Money salary;

  /// Recurring income, such as a scholarship (positive).
  final Money recurringIncome;

  /// Income that was recorded as transactions, such as a gift or a refund
  /// (positive). The salary and the recurring income are not in it.
  final Money otherIncome;

  /// Recurring costs, such as rent and services (negative).
  final Money fixedCosts;

  /// What was bought (negative).
  final Money purchases;

  /// Money that moved because of debts: repayments received are positive,
  /// repayments made negative.
  final Money debtMovements;

  /// The balance the server worked out, which is the one shown; `null` for
  /// figures the app made up itself (the fake data).
  final Money? reportedBalance;

  /// Everything that came in: the pay, the recurring income and the income
  /// transactions.
  Money get income => salary + recurringIncome + otherIncome;

  Money get spent => fixedCosts + purchases;

  /// What is left: income, spending and debt movements together.
  Money get balance => reportedBalance ?? income + spent + debtMovements;

  @override
  List<Object?> get props => [
    salary,
    recurringIncome,
    otherIncome,
    fixedCosts,
    purchases,
    debtMovements,
    reportedBalance,
  ];
}
