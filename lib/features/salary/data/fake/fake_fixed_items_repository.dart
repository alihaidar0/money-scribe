import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/salary/data/fake/fixed_items_seed.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';

/// Fixed items made of invented figures, until the server exists. It follows
/// the demo panel: no data, slow, failing or offline. What the app adds,
/// changes or deletes is kept in memory for as long as it runs.
class FakeFixedItemsRepository implements FixedItemsRepository {
  new({required this._demo});

  final DemoController _demo;

  /// The months the app changed since it started; they replace the seed.
  final _edited = <YearMonth, List<FixedItem>>{};

  var _nextId = 1;

  @override
  Stream<void> get changes => _demo.dataChanges;

  @override
  Future<List<FixedItem>> items(YearMonth month) async {
    await _demo.simulateRequest();
    return _current(month);
  }

  @override
  Future<FixedItem> add(YearMonth month, FixedItemDraft draft) async {
    await _demo.simulateSave();
    final item = FixedItem.fromDraft('added-${_nextId++}', draft);
    _edited[month] = [..._current(month), item];
    return item;
  }

  @override
  Future<FixedItem> update(
    YearMonth month,
    String id,
    FixedItemDraft draft,
  ) async {
    await _demo.simulateSave();
    final items = _current(month);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) throw const ServerException();

    final item = FixedItem.fromDraft(id, draft);
    _edited[month] = [...items]..[index] = item;
    return item;
  }

  @override
  Future<void> delete(YearMonth month, String id) async {
    await _demo.simulateSave();
    _edited[month] = [
      for (final item in _current(month))
        if (item.id != id) item,
    ];
  }

  /// The items of [month], without waiting for the server.
  List<FixedItem> _current(YearMonth month) {
    final edited = _edited[month];
    if (edited != null) return List.unmodifiable(edited);
    if (_demo.settings.scenario == DemoScenario.empty) return const [];
    return List.unmodifiable(FixedItemsSeed.items(month));
  }
}
