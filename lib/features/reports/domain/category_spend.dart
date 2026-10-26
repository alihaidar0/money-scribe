import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/money/money.dart';

/// What was spent on one category in a period. The fixed costs make one more
/// slice, [CategorySpend.fixedCosts], because they have no category.
final class CategorySpend extends Equatable {
  const new({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.amount,
    this.key,
  }) : isFixedCosts = false;

  /// The slice of the recurring costs (rent, services and so on), which are
  /// kept apart from the purchases and have no category of their own.
  const new fixedCosts(this.amount)
    : categoryId = '',
      name = 'Fixed costs',
      icon = CategoryIcon.housing,
      key = null,
      isFixedCosts = true;

  final String categoryId;

  /// The name of a category the person made, or the English name the server
  /// sends for a built-in one, which the screens replace by their own.
  final String name;
  final CategoryIcon icon;

  /// The stable key of a built-in category; `null` for one the person made.
  final String? key;

  /// What was spent, always positive.
  final Money amount;

  /// Whether this is the slice of the fixed costs, not a category.
  final bool isFixedCosts;

  @override
  List<Object?> get props => [
    categoryId,
    name,
    icon,
    key,
    amount,
    isFixedCosts,
  ];
}
