import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/salary/data/fake/fixed_items_seed.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_copy_refusal.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';

/// Fixed items made of invented figures, until the server exists. It follows
/// the demo panel: no data, slow, failing or offline. What the app adds,
/// changes or deletes is kept in memory for as long as it runs.
///
/// It asks [_salary] which months are saved, as the server knows it: copying
/// needs a saved month to copy to and an earlier one to copy from.
class FakeFixedItemsRepository implements FixedItemsRepository {
  new({required this._demo, required this._salary});

  /// The most fixed items a month holds, as on the server.
  static const _limit = 100;

  final DemoController _demo;
  final SalaryRepository _salary;

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
    FixedItemDraft draft, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final items = _current(month);
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0 || items[index].version != version) {
      throw const StaleRecordException();
    }

    final item = FixedItem.fromDraft(id, draft, version: version + 1);
    _edited[month] = [...items]..[index] = item;
    return item;
  }

  @override
  Future<void> delete(
    YearMonth month,
    String id, {
    required int version,
  }) async {
    await _demo.simulateSave();
    final current = _current(month).where((item) => item.id == id).firstOrNull;
    if (current != null && current.version != version) {
      throw const StaleRecordException();
    }
    _edited[month] = [
      for (final item in _current(month))
        if (item.id != id) item,
    ];
  }

  @override
  Future<List<FixedItem>> copyFromPrevious(YearMonth month) async {
    await _demo.simulateSave();
    final saved = await _salary.savedMonths();
    final target = saved.where((entry) => entry.month == month).firstOrNull;
    // Newest first, so the first one before [month] is the most recent.
    final source = saved.where((entry) => entry.month < month).firstOrNull;
    if (target == null || source == null) {
      throw const FixedItemsCopyRefusedException(
        FixedItemsCopyRefusal.noEarlierMonth,
      );
    }
    if (target.inputs.baseSalary.currency !=
        source.inputs.baseSalary.currency) {
      throw const FixedItemsCopyRefusedException(
        FixedItemsCopyRefusal.currencyMismatch,
      );
    }

    final current = _current(month);
    final copied = _current(source.month);
    if (current.length + copied.length > _limit) {
      throw const FixedItemsCopyRefusedException(
        FixedItemsCopyRefusal.limitReached,
      );
    }
    final items = [
      ...current,
      for (final item in copied)
        FixedItem.fromDraft('added-${_nextId++}', item.draft),
    ];
    _edited[month] = items;
    return List.unmodifiable(items);
  }

  /// The items of [month], without waiting for the server.
  List<FixedItem> _current(YearMonth month) {
    final edited = _edited[month];
    if (edited != null) return List.unmodifiable(edited);
    if (_demo.settings.scenario == DemoScenario.empty) return const [];
    return List.unmodifiable(FixedItemsSeed.items(month));
  }
}
