import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// The categories of the fake server. It follows the demo panel's slow,
/// failing and offline answers.
class FakeCategoriesRepository implements CategoriesRepository {
  new({required this._demo});

  final DemoController _demo;

  @override
  Future<List<TransactionCategory>> categories() async {
    await _demo.simulateRequest();
    return TransactionsSeed.categories;
  }
}
