import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/transactions/domain/account.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// Invented transactions, accounts and categories for the fake server, from
/// the sample of `docs/DESIGN.md` (October 2026). Never the owner's real
/// figures.
abstract final class TransactionsSeed {
  static Money _rub(int kopecks) => Money(kopecks, Currency.rub);

  static const accounts = [
    Account(id: 'card', name: 'Card', kind: AccountKind.card),
    Account(id: 'cash', name: 'Cash', kind: AccountKind.cash),
  ];

  static const categories = [
    TransactionCategory(
      id: 'groceries',
      name: 'Groceries',
      icon: CategoryIcon.groceries,
    ),
    TransactionCategory(
      id: 'dining',
      name: 'Dining',
      icon: CategoryIcon.dining,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Transport',
      icon: CategoryIcon.transport,
    ),
    TransactionCategory(
      id: 'housing',
      name: 'Housing',
      icon: CategoryIcon.housing,
    ),
    TransactionCategory(
      id: 'utilities',
      name: 'Utilities',
      icon: CategoryIcon.utilities,
    ),
    TransactionCategory(
      id: 'scholarship',
      name: 'Scholarship',
      icon: CategoryIcon.scholarship,
      kind: CategoryKind.income,
    ),
    TransactionCategory(
      id: 'other',
      name: 'Other',
      icon: CategoryIcon.other,
      kind: CategoryKind.both,
    ),
    TransactionCategory(
      id: 'gifts',
      name: 'Gifts',
      icon: CategoryIcon.gifts,
      kind: CategoryKind.both,
      isCustom: true,
    ),
  ];

  /// The transactions, in the order they were added (the oldest first).
  static List<Transaction> transactions() {
    return [
      Transaction(
        id: 'seed-scholarship',
        amount: _rub(500000),
        kind: TransactionKind.income,
        date: DateTime(2026, 10),
        categoryId: 'scholarship',
        accountId: 'card',
      ),
      Transaction(
        id: 'seed-groceries',
        amount: _rub(128450),
        kind: TransactionKind.expense,
        date: DateTime(2026, 10, 5),
        categoryId: 'groceries',
        accountId: 'card',
        note: 'Weekly shopping',
      ),
      Transaction(
        id: 'seed-coffee',
        amount: _rub(22000),
        kind: TransactionKind.expense,
        date: DateTime(2026, 10, 17),
        categoryId: 'dining',
        accountId: 'cash',
        note: 'Coffee',
      ),
      Transaction(
        id: 'seed-taxi',
        amount: _rub(64000),
        kind: TransactionKind.expense,
        date: DateTime(2026, 10, 19),
        categoryId: 'transport',
        accountId: 'card',
        note: 'Taxi',
      ),
    ];
  }
}
