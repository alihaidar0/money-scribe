import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/money/money.dart';

/// What was spent on one category in a period.
final class CategorySpend extends Equatable {
  const new({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.amount,
  });

  final String categoryId;
  final String name;
  final CategoryIcon icon;

  /// What was spent, always positive.
  final Money amount;

  @override
  List<Object> get props => [categoryId, name, icon, amount];
}
