import 'dart:async';

import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// The categories of the fake server. It follows the demo panel's slow,
/// failing and offline answers. What the app adds, changes or deletes is kept
/// in memory for as long as it runs. With `transactions`, deleting a category
/// moves its transactions to Other, as the server does.
class FakeCategoriesRepository implements CategoriesRepository {
  new({required this._demo, this._transactions});

  /// The category that takes the transactions of a deleted one.
  static const otherId = 'other';

  final DemoController _demo;
  final FakeTransactionsRepository? _transactions;
  final _changes = StreamController<void>.broadcast();

  List<TransactionCategory>? _edited;
  var _nextId = 1;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<TransactionCategory>> categories() async {
    await _demo.simulateRequest();
    return List.unmodifiable(_current());
  }

  @override
  Future<TransactionCategory> add(CategoryDraft draft) async {
    await _demo.simulateSave();
    final category = TransactionCategory(
      id: 'added-${_nextId++}',
      name: draft.name,
      icon: draft.icon,
      kind: CategoryKind.both,
      isCustom: true,
    );
    _edited = [..._current(), category];
    _changes.add(null);
    return category;
  }

  @override
  Future<TransactionCategory> update(String id, CategoryDraft draft) async {
    await _demo.simulateSave();
    final categories = _current();
    final index = categories.indexWhere((category) => category.id == id);
    if (index < 0 || !categories[index].isCustom) throw const ServerException();

    final category = TransactionCategory(
      id: id,
      name: draft.name,
      icon: draft.icon,
      kind: categories[index].kind,
      isCustom: true,
    );
    _edited = [...categories]..[index] = category;
    _changes.add(null);
    return category;
  }

  @override
  Future<void> delete(String id) async {
    await _demo.simulateSave();
    final categories = _current();
    final category = categories.where((category) => category.id == id);
    if (category.isEmpty) return;
    if (!category.first.isCustom) throw const ServerException();

    _transactions?.moveCategory(from: id, to: otherId);
    _edited = [
      for (final category in categories)
        if (category.id != id) category,
    ];
    _changes.add(null);
  }

  List<TransactionCategory> _current() =>
      _edited ?? TransactionsSeed.categories;
}
