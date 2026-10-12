import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_summary.dart';
import 'package:money_scribe/features/salary/domain/salary_history_entry.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

part 'fixed_items_event.dart';
part 'fixed_items_state.dart';

/// The Fixed items screen: the recurring income and costs of one month, the
/// balance they leave of the month's pay, and adding, changing and deleting
/// them.
class FixedItemsBloc extends Bloc<FixedItemsEvent, FixedItemsState> {
  new({
    required this._fixedItems,
    required this._salary,
    required YearMonth month,
  }) : super(FixedItemsState(month: month)) {
    _changes = [
      _fixedItems.changes.listen((_) => add(const FixedItemsDataChanged())),
      _salary.changes.listen((_) => add(const FixedItemsDataChanged())),
    ];
    on<FixedItemsStarted>(_onStarted, transformer: droppable());
    on<FixedItemsRetried>(_onRetried, transformer: droppable());
    on<FixedItemsDataChanged>(_onDataChanged, transformer: restartable());
    on<FixedItemsPartSelected>(_onPartSelected, transformer: sequential());
    on<FixedItemAdded>(_onAdded, transformer: sequential());
    on<FixedItemChanged>(_onChanged, transformer: sequential());
    on<FixedItemDeleted>(_onDeleted, transformer: sequential());
  }

  final FixedItemsRepository _fixedItems;
  final SalaryRepository _salary;

  late final List<StreamSubscription<void>> _changes;

  Future<void> _onStarted(
    FixedItemsStarted event,
    Emitter<FixedItemsState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onRetried(
    FixedItemsRetried event,
    Emitter<FixedItemsState> emit,
  ) {
    return _load(emit);
  }

  Future<void> _onDataChanged(
    FixedItemsDataChanged event,
    Emitter<FixedItemsState> emit,
  ) {
    return _load(emit);
  }

  void _onPartSelected(
    FixedItemsPartSelected event,
    Emitter<FixedItemsState> emit,
  ) {
    emit(state.copyWith(part: event.part));
  }

  Future<void> _onAdded(FixedItemAdded event, Emitter<FixedItemsState> emit) {
    return _run(event, emit, () async {
      final item = await _fixedItems.add(state.month, event.draft);
      emit(state.copyWith(items: [...state.items, item]));
    });
  }

  Future<void> _onChanged(
    FixedItemChanged event,
    Emitter<FixedItemsState> emit,
  ) {
    return _run(event, emit, () async {
      final saved = await _fixedItems.update(
        state.month,
        event.id,
        event.draft,
      );
      emit(
        state.copyWith(
          items: [
            for (final item in state.items)
              if (item.id == event.id) saved else item,
          ],
        ),
      );
    });
  }

  Future<void> _onDeleted(
    FixedItemDeleted event,
    Emitter<FixedItemsState> emit,
  ) {
    return _run(event, emit, () async {
      await _fixedItems.delete(state.month, event.id);
      emit(
        state.copyWith(
          items: [
            for (final item in state.items)
              if (item.id != event.id) item,
          ],
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    for (final subscription in _changes) {
      await subscription.cancel();
    }
    await super.close();
  }

  /// Does [action], which saves [event] on the server. When the server does
  /// not accept it the list stays as it was and [FixedItemsState.failedAction]
  /// holds [event], so the screen can offer to try again.
  Future<void> _run(
    FixedItemsEvent event,
    Emitter<FixedItemsState> emit,
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

  Future<void> _load(Emitter<FixedItemsState> emit) async {
    emit(
      state.copyWith(status: FixedItemsStatus.loading, clearFailedAction: true),
    );
    try {
      final results = await Future.wait<Object?>([
        _fixedItems.items(state.month),
        _salary.month(state.month),
      ]);
      final items = results[0]! as List<FixedItem>;
      final saved = results[1] as SalaryMonth?;
      final defaultMode = saved == null
          ? (await _salary.defaults()).paymentMode
          : null;

      final entry = saved == null ? null : SalaryHistoryEntry.tryFrom(saved);
      final mode = saved?.inputs.paymentMode ?? defaultMode;
      emit(
        state.copyWith(
          status: FixedItemsStatus.ready,
          items: items,
          salary: entry?.result,
          clearSalary: entry == null,
          twoPayments: mode == PaymentMode.twoPayments,
          currency: saved?.inputs.baseSalary.currency ?? Currency.rub,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: FixedItemsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      // A load that was replaced by a newer one has nothing to report.
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(status: FixedItemsStatus.failure));
    }
  }
}
