import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';

/// Where the fixed items come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class FixedItemsRepository {
  /// Emits when the fixed items may have changed without the app saving them,
  /// so a screen showing them loads them again.
  Stream<void> get changes;

  /// The fixed items of [month], in the order they were added.
  Future<List<FixedItem>> items(YearMonth month);

  /// Adds the item [draft] to [month] and returns it with its id.
  Future<FixedItem> add(YearMonth month, FixedItemDraft draft);

  /// Replaces what the item [id] of [month] is made of and returns it.
  Future<FixedItem> update(YearMonth month, String id, FixedItemDraft draft);

  /// Deletes the item [id] of [month]. Deleting an item that is gone does
  /// nothing.
  Future<void> delete(YearMonth month, String id);
}
