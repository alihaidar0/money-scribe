import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/salary_figures.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// What is left of the pay once the fixed items are counted: the pay, plus the
/// income items, minus the expense items. For a month paid in two payments it
/// is the figure of one part, with the whole month beside it.
final class FixedItemsSummary extends Equatable {
  const new({required this.pay, required this.balance, this.wholeMonth});

  /// The summary of [items], with the pay taken from [salary]. A month with no
  /// saved salary (`null`) has a pay of nothing.
  ///
  /// The balances are the ones the server calculated, when [balances] has
  /// them: the server's figures are the ones shown. Without them (the items
  /// changed and the server has not answered yet, or the data is not the
  /// server's) they are added up here from the same lines.
  new of({
    required List<FixedItem> items,
    required SalaryResult? salary,
    required Currency currency,
    required bool twoPayments,
    FixedItemPart part = FixedItemPart.first,
    SalaryBalances? balances,
  }) : pay = _pay(salary, currency, twoPayments, part),
       balance =
           _serverBalance(balances, twoPayments, part) ??
           _pay(salary, currency, twoPayments, part) +
               _sum(
                 shown(items, twoPayments: twoPayments, part: part),
                 Money.zero(currency),
               ),
       wholeMonth = twoPayments
           ? balances?.month ??
                 (salary?.totalAfterTax ?? Money.zero(currency)) +
                     _sum(items, Money.zero(currency))
           : null;

  /// The balance the server gave for what is shown, if it gave one.
  static Money? _serverBalance(
    SalaryBalances? balances,
    bool twoPayments,
    FixedItemPart part,
  ) {
    if (balances == null) return null;
    if (!twoPayments) return balances.month;
    return part == FixedItemPart.first ? balances.first : balances.second;
  }

  /// The items a screen shows: all of them for a month paid in one payment,
  /// those of [part] for a month paid in two.
  static List<FixedItem> shown(
    List<FixedItem> items, {
    required bool twoPayments,
    required FixedItemPart part,
  }) {
    if (!twoPayments) return items;
    return [
      for (final item in items)
        if (item.part == part) item,
    ];
  }

  /// What is paid: the whole month, or the pay of [part] for a month paid in
  /// two payments.
  static Money _pay(
    SalaryResult? salary,
    Currency currency,
    bool twoPayments,
    FixedItemPart part,
  ) {
    final zero = Money.zero(currency);
    if (salary == null) return zero;
    if (!twoPayments) return salary.totalAfterTax;
    return salary.payments.length == 2 ? salary.payments[part.index] : zero;
  }

  static Money _sum(List<FixedItem> items, Money zero) {
    return items.fold(zero, (sum, item) => sum + item.signedAmount);
  }

  /// What is paid: the whole month, or the part's pay.
  final Money pay;

  /// The pay with the fixed items counted.
  final Money balance;

  /// The balance of the whole month, for a month paid in two payments.
  final Money? wholeMonth;

  @override
  List<Object?> get props => [pay, balance, wholeMonth];
}
