import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/time/duration_seconds.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

part 'csv_export_password_event.dart';
part 'csv_export_password_state.dart';

/// The dialog that confirms the password before an export: the server checks
/// it and makes the file, a wrong one is said under the field, and too many
/// wrong ones (or too many exports) lock the field and the button with the
/// countdown the server gave.
class CsvExportPasswordBloc
    extends Bloc<CsvExportPasswordEvent, CsvExportPasswordState> {
  new({
    required this._repository,
    required this._ticker,
    required this._request,
  }) : super(const CsvExportPasswordState()) {
    on<CsvExportPasswordEdited>(_onEdited, transformer: sequential());
    // A second press while the file is being made is ignored.
    on<CsvExportPasswordSubmitted>(_onSubmitted, transformer: droppable());
    on<_CsvExportWaitTicked>(_onWaitTicked, transformer: sequential());
  }

  final CsvTransferRepository _repository;
  final Ticker _ticker;
  final CsvExportRequest _request;
  StreamSubscription<int>? _waitTimer;

  void _onEdited(
    CsvExportPasswordEdited event,
    Emitter<CsvExportPasswordState> emit,
  ) {
    emit(
      CsvExportPasswordState(
        // Typing after a refusal starts a new try; a wait the server asked for
        // goes on.
        status: state.status == CsvExportPasswordStatus.waiting
            ? CsvExportPasswordStatus.waiting
            : CsvExportPasswordStatus.editing,
        password: event.password,
        waitSecondsLeft: state.waitSecondsLeft,
      ),
    );
  }

  Future<void> _onSubmitted(
    CsvExportPasswordSubmitted event,
    Emitter<CsvExportPasswordState> emit,
  ) async {
    if (state.password.isEmpty ||
        state.status == CsvExportPasswordStatus.waiting) {
      return;
    }
    emit(state.copyWith(status: CsvExportPasswordStatus.exporting));
    try {
      await _repository.export(_request, password: state.password);
      emit(state.copyWith(status: CsvExportPasswordStatus.done));
    } on CsvExportRefusedException {
      emit(state.copyWith(status: CsvExportPasswordStatus.wrongPassword));
    } on TooManyRequestsException catch (error) {
      final seconds = error.retryAfter.ceilSeconds;
      emit(
        state.copyWith(
          status: CsvExportPasswordStatus.waiting,
          waitSecondsLeft: seconds,
        ),
      );
      _startWaitTimer(seconds);
    } on ServiceUnavailableException {
      emit(state.copyWith(status: CsvExportPasswordStatus.unavailable));
    } on NoConnectionException {
      emit(state.copyWith(status: CsvExportPasswordStatus.noConnection));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: CsvExportPasswordStatus.failure));
    }
  }

  void _onWaitTicked(
    _CsvExportWaitTicked event,
    Emitter<CsvExportPasswordState> emit,
  ) {
    if (state.status != CsvExportPasswordStatus.waiting) return;
    emit(
      event.secondsLeft > 0
          ? state.copyWith(waitSecondsLeft: event.secondsLeft)
          : state.copyWith(
              status: CsvExportPasswordStatus.editing,
              waitSecondsLeft: 0,
            ),
    );
  }

  void _startWaitTimer(int seconds) {
    unawaited(_waitTimer?.cancel());
    _waitTimer = _ticker
        .countdown(seconds)
        .listen((left) => add(_CsvExportWaitTicked(left)));
  }

  @override
  Future<void> close() async {
    await _waitTimer?.cancel();
    await super.close();
  }
}
