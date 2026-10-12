import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// Where the categories come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class CategoriesRepository {
  /// Emits when the categories changed, so a screen showing them loads them
  /// again.
  Stream<void> get changes;

  /// Every category, in the order the person arranged them.
  Future<List<TransactionCategory>> categories();

  /// Adds the category [draft] and returns it with its id.
  Future<TransactionCategory> add(CategoryDraft draft);

  /// Replaces what the category [id] is made of and returns it. A built-in
  /// category cannot be changed.
  Future<TransactionCategory> update(String id, CategoryDraft draft);

  /// Deletes the category [id]; its transactions move to Other. A built-in
  /// category cannot be deleted. Deleting one that is gone does nothing.
  Future<void> delete(String id);
}
