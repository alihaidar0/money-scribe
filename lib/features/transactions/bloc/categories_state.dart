part of 'categories_bloc.dart';

enum CategoriesStatus {
  /// The categories are being loaded.
  loading,

  /// The categories are shown.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class CategoriesState extends Equatable {
  const new({
    this.status = CategoriesStatus.loading,
    this.categories = const [],
    this.failedAction,
    this.staleAction,
    this.refusal,
  });

  final CategoriesStatus status;

  /// Every category, in the order the person arranged them.
  final List<TransactionCategory> categories;

  /// The last add, change or delete that the server did not accept, so the
  /// screen can offer to try it again. `null` once something else was done.
  final CategoriesEvent? failedAction;

  /// The last change or delete that was refused because the category was
  /// changed on another device; the list was loaded again. `null` once
  /// something else was done.
  final CategoriesEvent? staleAction;

  /// Why the last add or change was refused, if the person can act on it. It
  /// stays until something else is done.
  final CategoryRefusal? refusal;

  CategoriesState copyWith({
    CategoriesStatus? status,
    List<TransactionCategory>? categories,
    CategoriesEvent? failedAction,
    CategoriesEvent? staleAction,
    CategoryRefusal? refusal,
    bool clearFailedAction = false,
    bool clearStaleAction = false,
    bool clearRefusal = false,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
      staleAction: clearStaleAction ? null : staleAction ?? this.staleAction,
      refusal: clearRefusal ? null : refusal ?? this.refusal,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    failedAction,
    staleAction,
    refusal,
  ];
}
