import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_copy_refusal.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_summary.dart';
import 'package:money_scribe/features/salary/domain/salary_figures.dart';
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
    on<FixedItemsRefreshed>(_onRefreshed, transformer: restartable());
    on<FixedItemsPartSelected>(_onPartSelected, transformer: sequential());
    on<FixedItemAdded>(_onAdded, transformer: sequential());
    on<FixedItemChanged>(_onChanged, transformer: sequential());
    on<FixedItemDeleted>(_onDeleted, transformer: sequential());
    // A second press while the first copy runs would copy everything twice.
    on<FixedItemsCopied>(_onCopied, transformer: droppable());
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

  Future<void> _onRefreshed(
    FixedItemsRefreshed event,
    Emitter<FixedItemsState> emit,
  ) async {
    try {
      await _load(emit, silent: true);
    } finally {
      event.done?.complete();
    }
  }

  void _onPartSelected(
    FixedItemsPartSelected event,
    Emitter<FixedItemsState> emit,
  ) {
    emit(state.copyWith(part: event.part));
  }

  Future<void> _onAdded(FixedItemAdded event, Emitter<FixedItemsState> emit) {
    // The server refuses an item for a month that is not saved.
    if (!state.monthSaved) return Future.value();
    return _run(event, emit, () async {
      final item = await _fixedItems.add(state.month, event.draft);
      await _itemsChanged(emit, [...state.items, item]);
    });
  }

  Future<void> _onChanged(
    FixedItemChanged event,
    Emitter<FixedItemsState> emit,
  ) {
    return _run(event, emit, () async {
      final current = _itemOf(event.id);
      final saved = await _fixedItems.update(
        state.month,
        event.id,
        event.draft,
        version: current.version,
      );
      await _itemsChanged(emit, [
        for (final item in state.items)
          if (item.id == event.id) saved else item,
      ]);
    });
  }

  Future<void> _onDeleted(
    FixedItemDeleted event,
    Emitter<FixedItemsState> emit,
  ) {
    return _run(event, emit, () async {
      final current = _itemOf(event.id);
      await _fixedItems.delete(state.month, event.id, version: current.version);
      await _itemsChanged(emit, [
        for (final item in state.items)
          if (item.id != event.id) item,
      ]);
    });
  }

  Future<void> _onCopied(
    FixedItemsCopied event,
    Emitter<FixedItemsState> emit,
  ) async {
    // The server has no month to copy into until the salary is saved.
    if (!state.monthSaved) return;

    emit(state.copyWith(copying: true));
    await _run(event, emit, () async {
      final items = await _fixedItems.copyFromPrevious(state.month);
      await _itemsChanged(emit, items);
    });
    emit(state.copyWith(copying: false));
  }

  /// The items are now [items]. The balances the server gave are out of date,
  /// so the summary adds them up here until the server's come: a change of an
  /// item does not answer with them, so the month is read again.
  Future<void> _itemsChanged(
    Emitter<FixedItemsState> emit,
    List<FixedItem> items,
  ) async {
    final hadServerBalances = state.balances != null;
    emit(state.copyWith(items: items, clearBalances: true));
    if (!hadServerBalances) return;

    try {
      final saved = await _salary.month(state.month);
      emit(state.copyWith(balances: saved?.figures?.balances));
    } on Exception {
      // The summary keeps adding them up here; the next load asks again.
    }
  }

  @override
  Future<void> close() async {
    for (final subscription in _changes) {
      await subscription.cancel();
    }
    await super.close();
  }

  /// The item [id] as the list shows it. An item that is not there was deleted
  /// on another device, which is the same as a version that moved on.
  FixedItem _itemOf(String id) {
    return state.items.firstWhere(
      (item) => item.id == id,
      orElse: () => throw const StaleRecordException(),
    );
  }

  /// Does [action], which saves [event] on the server. When the server does
  /// not accept it the list stays as it was and [FixedItemsState.failedAction]
  /// holds [event], so the screen can offer to try again. When the item was
  /// changed on another device the list is loaded again and
  /// [FixedItemsState.staleAction] holds [event], so the screen can offer to
  /// apply it to what is there now. When a copy is refused for a reason the
  /// person can act on, [FixedItemsState.copyRefusal] holds it.
  Future<void> _run(
    FixedItemsEvent event,
    Emitter<FixedItemsState> emit,
    Future<void> Function() action,
  ) async {
    emit(
      state.copyWith(
        clearFailedAction: true,
        clearStaleAction: true,
        clearCopyRefusal: true,
      ),
    );
    try {
      await action();
    } on StaleRecordException {
      await _load(emit);
      emit(state.copyWith(staleAction: event));
    } on FixedItemsCopyRefusedException catch (refused) {
      emit(state.copyWith(copyRefusal: refused.refusal));
    } on NoConnectionException {
      emit(state.copyWith(failedAction: event));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(failedAction: event));
    }
  }

  /// Loads the month. A [silent] load of a screen that already shows it keeps
  /// showing it until the new items come, and keeps it when they do not.
  Future<void> _load(
    Emitter<FixedItemsState> emit, {
    bool silent = false,
  }) async {
    final keepShown = silent && state.status == FixedItemsStatus.ready;
    emit(
      state.copyWith(
        status: keepShown ? state.status : FixedItemsStatus.loading,
        clearFailedAction: true,
      ),
    );
    try {
      final results = await Future.wait<Object?>([
        _fixedItems.items(state.month),
        _salary.month(state.month),
      ]);
      final items = results[0]! as List<FixedItem>;
      final saved = results[1] as SalaryMonth?;
      final defaultMode = saved == null
          ? (await _salary.defaults(state.month)).paymentMode
          : null;

      final entry = saved == null ? null : SalaryHistoryEntry.tryFrom(saved);
      final mode = saved?.inputs.paymentMode ?? defaultMode;
      emit(
        state.copyWith(
          status: FixedItemsStatus.ready,
          monthSaved: saved != null,
          // The server deletes the items with the month.
          items: saved == null ? const [] : items,
          salary: entry?.result,
          clearSalary: entry == null,
          balances: saved?.figures?.balances,
          clearBalances: saved?.figures == null,
          twoPayments: mode == PaymentMode.twoPayments,
          currency: saved?.inputs.baseSalary.currency ?? Currency.rub,
        ),
      );
    } on NoConnectionException {
      if (keepShown) return;
      emit(state.copyWith(status: FixedItemsStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      // A load that was replaced by a newer one has nothing to report.
      if (emit.isDone) return;
      addError(error, stackTrace);
      if (keepShown) return;
      emit(state.copyWith(status: FixedItemsStatus.failure));
    }
  }
}
