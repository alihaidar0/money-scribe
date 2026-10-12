part of 'categories_bloc.dart';

sealed class CategoriesEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The Categories screen opened: load the categories.
final class CategoriesStarted extends CategoriesEvent {
  const new();
}

/// The user pressed Try again.
final class CategoriesRetried extends CategoriesEvent {
  const new();
}

/// The user added a category in the sheet.
final class CategoryAdded extends CategoriesEvent {
  const new(this.draft);

  final CategoryDraft draft;

  @override
  List<Object> get props => [draft];
}

/// The user changed the category [id] in the sheet.
final class CategoryChanged extends CategoriesEvent {
  const new(this.id, this.draft);

  final String id;
  final CategoryDraft draft;

  @override
  List<Object> get props => [id, draft];
}

/// The user deleted the category [id].
final class CategoryDeleted extends CategoriesEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}
