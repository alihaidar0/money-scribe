import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

/// Which transactions a category is for.
enum CategoryKind { expense, income, both }

/// What a transaction was for, such as groceries or rent.
final class TransactionCategory extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.icon,
    this.kind = CategoryKind.expense,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final CategoryIcon icon;
  final CategoryKind kind;

  /// Whether the person made this category. The built-in ones cannot be
  /// changed or deleted.
  final bool isCustom;

  /// Whether a transaction of [transactionKind] can be put in this category.
  bool isFor(TransactionKind transactionKind) {
    return switch (kind) {
      CategoryKind.both => true,
      CategoryKind.expense => transactionKind == TransactionKind.expense,
      CategoryKind.income => transactionKind == TransactionKind.income,
    };
  }

  @override
  List<Object> get props => [id, name, icon, kind, isCustom];
}

/// A category as it is typed, before the server gives it an id. A category the
/// person makes is for expenses and income alike.
final class CategoryDraft extends Equatable {
  const new({required this.name, required this.icon});

  /// The most characters a name has.
  static const maxNameLength = 30;

  /// The draft of what was typed, or `null` while the name is empty or too
  /// long.
  static CategoryDraft? tryCreate({
    required String name,
    required CategoryIcon icon,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxNameLength) return null;
    return CategoryDraft(name: trimmed, icon: icon);
  }

  final String name;
  final CategoryIcon icon;

  @override
  List<Object> get props => [name, icon];
}
