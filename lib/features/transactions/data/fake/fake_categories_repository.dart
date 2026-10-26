import 'dart:async';

import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/transactions_seed.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// The categories of the fake server. It follows the demo panel's slow,
/// failing and offline answers. What the app adds, changes or deletes is kept
/// in memory for as long as it runs. It keeps the rules of the server: a
/// custom name is used once (in any case) and is not the name of a built-in
/// category, there are at most [maxCustom] custom categories, a change or a
/// delete needs the version it was made from, and with `transactions`
/// deleting a category moves its transactions to Other.
class FakeCategoriesRepository implements CategoriesRepository {
  new({required this._demo, this._transactions});

  /// The category that takes the transactions of a deleted one.
  static const otherId = 'other';

  /// The most custom categories a person has.
  static const maxCustom = 50;

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
    final categories = _current();
    if (categories.where((category) => category.isCustom).length >= maxCustom) {
      throw const CategoryRefusedException(CategoryRefusal.limitReached);
    }
    _checkName(categories, draft.name);
    final category = TransactionCategory(
      id: 'added-${_nextId++}',
      name: draft.name,
      icon: draft.icon,
      kind: CategoryKind.both,
      isCustom: true,
    );
    _edited = [...categories, category];
    _changes.add(null);
    return category;
  }

  @override
  Future<TransactionCategory> update(
    String id,
    CategoryDraft draft, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final categories = _current();
    final index = categories.indexWhere((category) => category.id == id);
    if (index < 0 || categories[index].version != version) {
      throw const StaleRecordException();
    }
    final old = categories[index];
    // The server answers 403 for a built-in category; the screens never offer
    // to change one.
    if (!old.isCustom) throw const ServerException();
    _checkName(categories, draft.name, except: id);

    final unchanged = old.name == draft.name && old.icon == draft.icon;
    final category = TransactionCategory(
      id: id,
      name: draft.name,
      icon: draft.icon,
      kind: old.kind,
      isCustom: true,
      version: unchanged ? old.version : old.version + 1,
    );
    _edited = [...categories]..[index] = category;
    _changes.add(null);
    return category;
  }

  @override
  Future<void> delete(String id, {required int version}) async {
    await _demo.simulateSave();
    final categories = _current();
    final found = categories.where((category) => category.id == id);
    if (found.isEmpty) return;
    final category = found.first;
    if (!category.isCustom) throw const ServerException();
    if (category.version != version) throw const StaleRecordException();

    _transactions?.moveCategory(from: id, to: otherId);
    _edited = [
      for (final item in categories)
        if (item.id != id) item,
    ];
    _changes.add(null);
  }

  void _checkName(
    List<TransactionCategory> categories,
    String name, {
    String? except,
  }) {
    final wanted = name.trim().toLowerCase();
    final taken = categories.any(
      (category) =>
          category.id != except &&
          (category.name.toLowerCase() == wanted ||
              (category.key?.toLowerCase() ?? '') == wanted),
    );
    if (taken) throw const CategoryRefusedException(CategoryRefusal.nameTaken);
  }

  List<TransactionCategory> _current() =>
      _edited ?? TransactionsSeed.categories;
}
