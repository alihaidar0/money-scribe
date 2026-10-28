part of 'fixed_items_bloc.dart';

sealed class FixedItemsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: load the fixed items and the salary of the month.
final class FixedItemsStarted extends FixedItemsEvent {
  const new();
}

/// The user pressed Try again.
final class FixedItemsRetried extends FixedItemsEvent {
  const new();
}

/// The fixed items or the salary may have changed: load them again.
final class FixedItemsDataChanged extends FixedItemsEvent {
  const new();
}

/// The user pulled the list down: load the month again without the loading
/// state, then complete [done] so the spinner ends.
final class FixedItemsRefreshed extends FixedItemsEvent {
  const new({this.done});

  final Completer<void>? done;
}

/// The user chose which part to show, for a month paid in two payments.
final class FixedItemsPartSelected extends FixedItemsEvent {
  const new(this.part);

  final FixedItemPart part;

  @override
  List<Object> get props => [part];
}

/// The user saved a new item.
final class FixedItemAdded extends FixedItemsEvent {
  const new(this.draft);

  final FixedItemDraft draft;

  @override
  List<Object> get props => [draft];
}

/// The user saved changes to the item [id].
final class FixedItemChanged extends FixedItemsEvent {
  const new(this.id, this.draft);

  final String id;
  final FixedItemDraft draft;

  @override
  List<Object> get props => [id, draft];
}

/// The user asked to copy the fixed items of the last saved month into this
/// one (and confirmed, when this month already has some).
final class FixedItemsCopied extends FixedItemsEvent {
  const new();
}

/// The user confirmed deleting the item [id].
final class FixedItemDeleted extends FixedItemsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
