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
  });

  final CategoriesStatus status;

  /// Every category, in the order the person arranged them.
  final List<TransactionCategory> categories;

  /// The last add, change or delete that the server did not accept, so the
  /// screen can offer to try it again. `null` once something else was done.
  final CategoriesEvent? failedAction;

  CategoriesState copyWith({
    CategoriesStatus? status,
    List<TransactionCategory>? categories,
    CategoriesEvent? failedAction,
    bool clearFailedAction = false,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
    );
  }

  @override
  List<Object?> get props => [status, categories, failedAction];
}
