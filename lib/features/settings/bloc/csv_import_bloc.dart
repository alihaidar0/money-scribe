import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

part 'csv_import_event.dart';
part 'csv_import_state.dart';

/// The Import CSV screens: choosing a file, checking what it would import
/// (an estimate), importing its rows, then how it went. A file that cannot be
/// imported at all is said before anything is sent. An import that failed
/// part of the way goes on where it stopped when tried again.
class CsvImportBloc extends Bloc<CsvImportEvent, CsvImportState> {
  new({required this._repository}) : super(const CsvImportState()) {
    // The picker is open once, whatever is pressed meanwhile.
    on<CsvImportStarted>(_onFileRequested, transformer: droppable());
    on<CsvFileRequested>(_onFileRequested, transformer: droppable());
    on<CsvCheckRequested>(_onCheckRequested, transformer: droppable());
    on<CsvImportConfirmed>(_onConfirmed, transformer: droppable());
  }

  final CsvTransferRepository _repository;

  Future<void> _onFileRequested(
    CsvImportEvent event,
    Emitter<CsvImportState> emit,
  ) async {
    final previous = state.status == CsvImportStatus.ready ? state : null;
    emit(const CsvImportState());
    final CsvFile? file;
    try {
      file = await _repository.chooseFile();
    } on CsvFileException catch (error) {
      emit(
        CsvImportState(
          status: CsvImportStatus.fileProblem,
          fileIssue: error.issue,
          fileLimit: error.limit,
        ),
      );
      return;
    } on DataException catch (error, stackTrace) {
      emit(_failed(error, stackTrace, event));
      return;
    } on Exception catch (error, stackTrace) {
      // The phone could not hand the file over.
      addError(error, stackTrace);
      emit(
        const CsvImportState(
          status: CsvImportStatus.fileProblem,
          fileIssue: CsvFileIssue.unreadable,
        ),
      );
      return;
    }
    if (file == null) {
      // Closing the picker keeps the file that was chosen before.
      emit(previous ?? const CsvImportState(status: CsvImportStatus.noFile));
      return;
    }
    await _check(file, emit);
  }

  Future<void> _onCheckRequested(
    CsvCheckRequested event,
    Emitter<CsvImportState> emit,
  ) async {
    final file = state.file;
    if (file != null) await _check(file, emit);
  }

  Future<void> _check(CsvFile file, Emitter<CsvImportState> emit) async {
    emit(CsvImportState(status: CsvImportStatus.checking, file: file));
    try {
      final estimate = await _repository.check(file);
      emit(
        CsvImportState(
          status: CsvImportStatus.ready,
          file: file,
          estimate: estimate,
        ),
      );
    } on Exception catch (error, stackTrace) {
      emit(_failed(error, stackTrace, const CsvCheckRequested()));
    }
  }

  Future<void> _onConfirmed(
    CsvImportConfirmed event,
    Emitter<CsvImportState> emit,
  ) async {
    final file = state.file;
    // Also after a failed import: Try again goes on where it stopped.
    final canImport =
        state.status == CsvImportStatus.ready ||
        state.failedAction is CsvImportConfirmed;
    if (file == null || !canImport) return;
    emit(
      CsvImportState(
        status: CsvImportStatus.importing,
        file: file,
        estimate: state.estimate,
        rowsDone: state.rowsDone,
      ),
    );
    try {
      final result = await _repository.import(
        file,
        onProgress: (rowsDone) {
          if (!emit.isDone) emit(state.copyWith(rowsDone: rowsDone));
        },
      );
      emit(
        CsvImportState(
          status: CsvImportStatus.imported,
          file: file,
          result: result,
        ),
      );
    } on Exception catch (error, stackTrace) {
      emit(_failed(error, stackTrace, event));
    }
  }

  /// The state after [error], keeping the file, what was found and done, and
  /// [action], so Try again does it again.
  CsvImportState _failed(
    Exception error,
    StackTrace stackTrace,
    CsvImportEvent action,
  ) {
    final status = switch (error) {
      NoConnectionException() => CsvImportStatus.noConnection,
      ServiceUnavailableException() => CsvImportStatus.unavailable,
      _ => CsvImportStatus.failure,
    };
    if (status == CsvImportStatus.failure) addError(error, stackTrace);
    return CsvImportState(
      status: status,
      file: state.file,
      estimate: state.estimate,
      rowsDone: state.rowsDone,
      failedAction: action,
    );
  }
}
