import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

/// Which transactions a category is for.
enum CategoryKind { expense, income, both }

/// The picture of a category. The screens map each to an icon.
enum CategoryIcon {
  groceries,
  dining,
  transport,
  housing,
  utilities,
  scholarship,
  other,
}

/// What a transaction was for, such as groceries or rent.
final class TransactionCategory extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.icon,
    this.kind = CategoryKind.expense,
  });

  final String id;
  final String name;
  final CategoryIcon icon;
  final CategoryKind kind;

  /// Whether a transaction of [transactionKind] can be put in this category.
  bool isFor(TransactionKind transactionKind) {
    return switch (kind) {
      CategoryKind.both => true,
      CategoryKind.expense => transactionKind == TransactionKind.expense,
      CategoryKind.income => transactionKind == TransactionKind.income,
    };
  }

  @override
  List<Object> get props => [id, name, icon, kind];
}
