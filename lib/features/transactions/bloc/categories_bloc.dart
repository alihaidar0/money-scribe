import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

part 'categories_event.dart';
part 'categories_state.dart';

/// The Categories screen of the Settings: the built-in categories and the
/// ones the person made, which can be added, changed and deleted.
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  new({required this._repository}) : super(const CategoriesState()) {
    on<CategoriesStarted>(_onStarted, transformer: droppable());
    on<CategoriesRetried>(_onStarted, transformer: droppable());
    // One at a time, so the list is always what the last change made it.
    on<CategoryAdded>(_onAdded, transformer: sequential());
    on<CategoryChanged>(_onChanged, transformer: sequential());
    on<CategoryDeleted>(_onDeleted, transformer: sequential());
  }

  final CategoriesRepository _repository;

  Future<void> _onStarted(
    CategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CategoriesStatus.loading,
        clearFailedAction: true,
        clearStaleAction: true,
        clearRefusal: true,
      ),
    );
    try {
      final categories = await _repository.categories();
      emit(
        state.copyWith(status: CategoriesStatus.ready, categories: categories),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: CategoriesStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: CategoriesStatus.failure));
    }
  }

  Future<void> _onAdded(CategoryAdded event, Emitter<CategoriesState> emit) {
    return _run(event, emit, () async {
      final category = await _repository.add(event.draft);
      emit(state.copyWith(categories: [...state.categories, category]));
    });
  }

  Future<void> _onChanged(
    CategoryChanged event,
    Emitter<CategoriesState> emit,
  ) {
    return _run(event, emit, () async {
      final category = await _repository.update(
        event.id,
        event.draft,
        version: _categoryOf(event.id).version,
      );
      emit(
        state.copyWith(
          categories: [
            for (final item in state.categories)
              if (item.id == event.id) category else item,
          ],
        ),
      );
    });
  }

  Future<void> _onDeleted(
    CategoryDeleted event,
    Emitter<CategoriesState> emit,
  ) {
    return _run(event, emit, () async {
      await _repository.delete(
        event.id,
        version: _categoryOf(event.id).version,
      );
      emit(
        state.copyWith(
          categories: [
            for (final item in state.categories)
              if (item.id != event.id) item,
          ],
        ),
      );
    });
  }

  /// The category [id] as the list shows it. A category that is not there was
  /// deleted on another device, which is the same as a version that moved on.
  TransactionCategory _categoryOf(String id) {
    return state.categories.firstWhere(
      (category) => category.id == id,
      orElse: () => throw const StaleRecordException(),
    );
  }

  /// Does [action], which saves [event] on the server. When the server does
  /// not accept it the list stays as it was and [CategoriesState.failedAction]
  /// holds [event], so the screen can offer to try again. When the category
  /// was changed on another device the list is loaded again and
  /// [CategoriesState.staleAction] holds [event], so the screen can offer to
  /// apply it to what is there now. When the name is taken or there are too
  /// many categories, [CategoriesState.refusal] says so.
  Future<void> _run(
    CategoriesEvent event,
    Emitter<CategoriesState> emit,
    Future<void> Function() action,
  ) async {
    emit(
      state.copyWith(
        clearFailedAction: true,
        clearStaleAction: true,
        clearRefusal: true,
      ),
    );
    try {
      await action();
    } on StaleRecordException {
      await _reload(emit);
      emit(state.copyWith(staleAction: event));
    } on CategoryRefusedException catch (refused) {
      emit(state.copyWith(refusal: refused.refusal));
    } on NoConnectionException {
      emit(state.copyWith(failedAction: event));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(failedAction: event));
    }
  }

  /// Reads the categories again without the loading state. If the server
  /// cannot be reached the list stays as it was.
  Future<void> _reload(Emitter<CategoriesState> emit) async {
    try {
      emit(state.copyWith(categories: await _repository.categories()));
    } on Exception {
      // The list stays; the next load asks again.
    }
  }
}
