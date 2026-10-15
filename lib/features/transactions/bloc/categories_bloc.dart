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
      state.copyWith(status: CategoriesStatus.loading, clearFailedAction: true),
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
      final category = await _repository.update(event.id, event.draft);
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
      await _repository.delete(event.id);
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

  /// Does [action], which saves [event] on the server. When the server does
  /// not accept it the list stays as it was and [CategoriesState.failedAction]
  /// holds [event], so the screen can offer to try again.
  Future<void> _run(
    CategoriesEvent event,
    Emitter<CategoriesState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(clearFailedAction: true));
    try {
      await action();
    } on NoConnectionException {
      emit(state.copyWith(failedAction: event));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(failedAction: event));
    }
  }
}
