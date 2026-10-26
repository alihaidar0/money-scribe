// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'signed_amount.dart';

part 'overview_block.g.dart';

/// The figures of the whole month or of one part, all positive except the `balance`.
@JsonSerializable()
class OverviewBlock {
  const OverviewBlock({
    required this.salary,
    required this.recurringIncome,
    required this.fixedCosts,
    required this.incomeTransactions,
    required this.purchases,
    required this.debtRepaymentsReceived,
    required this.debtRepaymentsMade,
    required this.balance,
  });

  factory OverviewBlock.fromJson(Map<String, Object?> json) =>
      _$OverviewBlockFromJson(json);

  /// The saved month's total after tax, or the payment of this part; 0 if the month was not saved in this currency.
  final Amount salary;

  /// The saved month's fixed income of this part (all of it with one payment).
  @JsonKey(name: 'recurring_income')
  final Amount recurringIncome;

  /// The saved month's fixed expenses of this part (all of them with one payment).
  @JsonKey(name: 'fixed_costs')
  final Amount fixedCosts;

  /// Income transactions dated in the period. The salary and the recurring income are not included.
  @JsonKey(name: 'income_transactions')
  final Amount incomeTransactions;

  /// Expense transactions dated in the period. The fixed costs are not included.
  final Amount purchases;

  /// Repayments dated in the period on debts the person lent.
  @JsonKey(name: 'debt_repayments_received')
  final Amount debtRepaymentsReceived;

  /// Repayments dated in the period on debts the person borrowed.
  @JsonKey(name: 'debt_repayments_made')
  final Amount debtRepaymentsMade;

  /// `salary` + `recurring_income` + `income_transactions` - `fixed_costs` - `purchases` + `debt_repayments_received` - `debt_repayments_made`.
  final SignedAmount balance;

  Map<String, Object?> toJson() => _$OverviewBlockToJson(this);
}
