import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// Where the categories come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class CategoriesRepository {
  /// Emits when the categories changed, so a screen showing them loads them
  /// again.
  Stream<void> get changes;

  /// Every category, in the order the person arranged them.
  Future<List<TransactionCategory>> categories();

  /// Adds the category [draft] and returns it with its id. Throws
  /// [CategoryRefusedException] when the name is taken or the person has the
  /// most categories allowed.
  Future<TransactionCategory> add(CategoryDraft draft);

  /// Replaces what the category [id] is made of and returns it. [version] is
  /// the version the change was made from: a category that changed since
  /// throws a `StaleRecordException` and nothing is changed. A built-in
  /// category cannot be changed. Throws [CategoryRefusedException] when the
  /// name is taken.
  Future<TransactionCategory> update(
    String id,
    CategoryDraft draft, {
    required int version,
  });

  /// Deletes the category [id] at [version]; its transactions move to Other.
  /// A built-in category cannot be deleted. A category that changed since
  /// throws a `StaleRecordException`. Deleting one that is gone does nothing.
  Future<void> delete(String id, {required int version});
}
