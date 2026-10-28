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
    this.key,
    this.version = 1,
  });

  final String id;

  /// The name as the server sent it: the person's own for a custom category,
  /// the English one for a built-in category. The screens show a built-in
  /// category by its [key] in the language of the app.
  final String name;
  final CategoryIcon icon;
  final CategoryKind kind;

  /// The stable key of a built-in category (`groceries`, `dining`, ...), or
  /// `null` for one the person made.
  final String? key;

  /// The version of the record on the server (see `Account.version`).
  final int version;

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
  List<Object?> get props => [id, name, icon, kind, isCustom, key, version];
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

/// Why the server did not accept a category the person typed.
enum CategoryRefusal {
  /// Another custom category has this name, or it is the name of a built-in
  /// one (the names are compared in any case).
  nameTaken,

  /// The person has as many custom categories as the server allows.
  limitReached,
}

/// Thrown when the server refuses a category for a reason the person can act
/// on.
final class CategoryRefusedException implements Exception {
  const new(this.refusal);

  final CategoryRefusal refusal;

  @override
  String toString() => 'CategoryRefusedException($refusal)';
}
