import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/salary_history_entry.dart';

/// One of the two months that are compared.
enum CompareSide { left, right }

/// What a line of the comparison is about.
enum ComparisonLineKind {
  incomeBeforeTax,
  tax,
  totalAfterTax,

  /// The pay of one part of a month paid in two payments.
  payAfterTax,

  /// What the fixed items of one part add or take, with its sign.
  fixedItems,

  /// The pay of one part with its fixed items counted.
  balanceAfterFixedItems,
}

/// One line of the comparison: the figure of each month, and how much the
/// right one differs from the left one. A figure is `null` when that month has
/// no saved salary, or no such part.
final class ComparisonLine extends Equatable {
  const new({required this.kind, this.left, this.right});

  final ComparisonLineKind kind;
  final Money? left;
  final Money? right;

  /// The right figure minus the left one, so it is positive when the second
  /// month is higher. `null` when a figure is missing, or the two are in
  /// different currencies, which cannot be subtracted.
  Money? get difference {
    final left = this.left;
    final right = this.right;
    if (left == null || right == null || left.currency != right.currency) {
      return null;
    }
    return right - left;
  }

  @override
  List<Object?> get props => [kind, left, right];
}

/// Lines up two saved months. A month is compared whole, or by the same part
/// of both.
abstract final class SalaryComparison {
  /// Whether either month is paid in two payments, so the parts are worth
  /// comparing.
  static bool hasParts(SalaryHistoryEntry? left, SalaryHistoryEntry? right) {
    return _isSplit(left) || _isSplit(right);
  }

  /// The lines of the comparison of [left] and [right] over [scope]. A month
  /// that is not saved (`null`) has no figures. A part also counts the fixed
  /// items of each month ([leftItems], [rightItems]); while a month's items
  /// are not known (`null`) their lines have no figure for it.
  static List<ComparisonLine> lines(
    SalaryHistoryEntry? left,
    SalaryHistoryEntry? right,
    PeriodScope scope, {
    List<FixedItem>? leftItems,
    List<FixedItem>? rightItems,
  }) {
    return switch (scope) {
      PeriodScope.month => [
        ComparisonLine(
          kind: ComparisonLineKind.incomeBeforeTax,
          left: left?.result.incomeBeforeTax,
          right: right?.result.incomeBeforeTax,
        ),
        ComparisonLine(
          kind: ComparisonLineKind.tax,
          left: left?.result.tax,
          right: right?.result.tax,
        ),
        ComparisonLine(
          kind: ComparisonLineKind.totalAfterTax,
          left: left?.result.totalAfterTax,
          right: right?.result.totalAfterTax,
        ),
      ],
      PeriodScope.firstPart => _partLines(
        left,
        right,
        FixedItemPart.first,
        leftItems,
        rightItems,
      ),
      PeriodScope.secondPart => _partLines(
        left,
        right,
        FixedItemPart.second,
        leftItems,
        rightItems,
      ),
    };
  }

  /// Pay after tax, the fixed items and the balance they leave, for [part].
  static List<ComparisonLine> _partLines(
    SalaryHistoryEntry? left,
    SalaryHistoryEntry? right,
    FixedItemPart part,
    List<FixedItem>? leftItems,
    List<FixedItem>? rightItems,
  ) {
    final leftPay = _payment(left, part);
    final rightPay = _payment(right, part);
    final leftFixed = _fixed(leftPay, leftItems, part);
    final rightFixed = _fixed(rightPay, rightItems, part);

    return [
      ComparisonLine(
        kind: ComparisonLineKind.payAfterTax,
        left: leftPay,
        right: rightPay,
      ),
      ComparisonLine(
        kind: ComparisonLineKind.fixedItems,
        left: leftFixed,
        right: rightFixed,
      ),
      ComparisonLine(
        kind: ComparisonLineKind.balanceAfterFixedItems,
        left: leftPay == null || leftFixed == null ? null : leftPay + leftFixed,
        right: rightPay == null || rightFixed == null
            ? null
            : rightPay + rightFixed,
      ),
    ];
  }

  /// What the items of [part] add up to, or `null` when the month has no pay
  /// for the part or its items are not known.
  static Money? _fixed(Money? pay, List<FixedItem>? items, FixedItemPart part) {
    if (pay == null || items == null) return null;
    return items
        .where((item) => item.part == part)
        .fold<Money>(
          Money.zero(pay.currency),
          (sum, item) => sum + item.signedAmount,
        );
  }

  static bool _isSplit(SalaryHistoryEntry? entry) {
    return entry != null && entry.result.payments.length == 2;
  }

  /// The pay of [part], or `null` for a month that is not saved or is paid in
  /// one payment.
  static Money? _payment(SalaryHistoryEntry? entry, FixedItemPart part) {
    final payments = entry?.result.payments;
    if (payments == null || payments.length != 2) return null;
    return payments[part.index];
  }
}
