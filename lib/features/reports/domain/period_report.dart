import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/reports/domain/category_spend.dart';

/// The money of one period, a month or one part of it: what came in, what was
/// spent, and what the spending went on.
final class PeriodReport extends Equatable {
  const new({
    required this.income,
    required this.spent,
    required this.categories,
  });

  /// What came in (positive).
  final Money income;

  /// What was spent, as a positive amount.
  final Money spent;

  /// What the spending went on, the biggest first. No category is empty.
  final List<CategorySpend> categories;

  /// What the categories come to.
  Money get categoriesTotal {
    return categories.fold<Money>(
      Money.zero(spent.currency),
      (sum, category) => sum + category.amount,
    );
  }

  /// The share of [category] in the spending, in tenths of a percent (569 is
  /// 56.9 %), rounded half up. Nothing is spent: 0.
  int permilleOf(CategorySpend category) {
    final whole = categoriesTotal.minorUnits;
    if (whole <= 0) return 0;
    final numerator =
        BigInt.from(category.amount.minorUnits) * BigInt.from(2000) +
        BigInt.from(whole);
    return (numerator ~/ (BigInt.from(whole) * BigInt.two)).toInt();
  }

  @override
  List<Object> get props => [income, spent, categories];
}
