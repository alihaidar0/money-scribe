import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// Where the categories come from: the server. Can throw a `DataException`
/// when the server cannot be reached or fails.
abstract interface class CategoriesRepository {
  /// Every category, in the order the person arranged them.
  Future<List<TransactionCategory>> categories();
}
