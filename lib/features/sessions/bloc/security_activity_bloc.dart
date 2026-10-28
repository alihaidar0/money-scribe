import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

part 'security_activity_event.dart';
part 'security_activity_state.dart';

/// The Security activity screen: the timeline of the last 90 days, a page at
/// a time, newest first. The imports of one action are shown as one entry.
class SecurityActivityBloc
    extends Bloc<SecurityActivityEvent, SecurityActivityState> {
  new({required this._repository}) : super(const SecurityActivityState()) {
    on<SecurityActivityStarted>(_onStarted, transformer: droppable());
    on<SecurityActivityRetried>(_onStarted, transformer: droppable());
    on<SecurityActivityMoreRequested>(_onMore, transformer: droppable());
  }

  final SessionsRepository _repository;

  Future<void> _onStarted(
    SecurityActivityEvent event,
    Emitter<SecurityActivityState> emit,
  ) {
    return _load(emit, showLoading: true);
  }

  Future<void> _onMore(
    SecurityActivityMoreRequested event,
    Emitter<SecurityActivityState> emit,
  ) async {
    final cursor = state.next;
    if (cursor == null) return;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await _readWithItsGroup(
        await _repository.activity(cursor: cursor),
      );
      emit(
        state.copyWith(
          events: [...state.events, ...page.items],
          next: page.nextCursor,
          clearNext: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } on Exception catch (error, stackTrace) {
      if (error is! NoConnectionException) addError(error, stackTrace);
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }

  /// [page], and the pages after it while its last entry is an import: the
  /// imports of one action are put together, and a run that touches the end
  /// of the page goes on in the next one, so it is not shown cut in two.
  Future<SecurityEventsPage> _readWithItsGroup(SecurityEventsPage page) async {
    var events = page.items;
    var next = page.nextCursor;
    for (var reads = 0; reads < _maxExtraPages; reads++) {
      if (next == null ||
          events.isEmpty ||
          events.last.type != SecurityEventType.dataImported) {
        break;
      }
      final more = await _repository.activity(cursor: next);
      events = [...events, ...more.items];
      next = more.nextCursor;
    }
    return SecurityEventsPage(items: events, nextCursor: next);
  }

  /// The most pages read after a page to finish a run of imports.
  static const _maxExtraPages = 5;

  Future<void> _load(
    Emitter<SecurityActivityState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(state.copyWith(status: SecurityActivityStatus.loading));
    }
    try {
      final page = await _readWithItsGroup(await _repository.activity());
      emit(
        state.copyWith(
          status: SecurityActivityStatus.ready,
          events: page.items,
          next: page.nextCursor,
          clearNext: page.nextCursor == null,
          loadMoreFailed: false,
        ),
      );
    } on NoConnectionException {
      emit(state.copyWith(status: SecurityActivityStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      if (emit.isDone) return;
      addError(error, stackTrace);
      emit(state.copyWith(status: SecurityActivityStatus.failure));
    }
  }
}
