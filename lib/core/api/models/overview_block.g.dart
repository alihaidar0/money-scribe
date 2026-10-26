// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overview_block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OverviewBlock _$OverviewBlockFromJson(Map<String, dynamic> json) =>
    OverviewBlock(
      salary: json['salary'] as Amount,
      recurringIncome: json['recurring_income'] as Amount,
      fixedCosts: json['fixed_costs'] as Amount,
      incomeTransactions: json['income_transactions'] as Amount,
      purchases: json['purchases'] as Amount,
      debtRepaymentsReceived: json['debt_repayments_received'] as Amount,
      debtRepaymentsMade: json['debt_repayments_made'] as Amount,
      balance: json['balance'] as SignedAmount,
    );

Map<String, dynamic> _$OverviewBlockToJson(OverviewBlock instance) =>
    <String, dynamic>{
      'salary': instance.salary,
      'recurring_income': instance.recurringIncome,
      'fixed_costs': instance.fixedCosts,
      'income_transactions': instance.incomeTransactions,
      'purchases': instance.purchases,
      'debt_repayments_received': instance.debtRepaymentsReceived,
      'debt_repayments_made': instance.debtRepaymentsMade,
      'balance': instance.balance,
    };
