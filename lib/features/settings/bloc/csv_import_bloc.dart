import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer_repository.dart';

part 'csv_import_event.dart';
part 'csv_import_state.dart';

/// The Import CSV screens: choosing a file and importing its rows, then how
/// it went.
class CsvImportBloc extends Bloc<CsvImportEvent, CsvImportState> {
  new({required this._repository}) : super(const CsvImportState()) {
    // The picker is open once, whatever is pressed meanwhile.
    on<CsvImportStarted>(_onFileRequested, transformer: droppable());
    on<CsvFileRequested>(_onFileRequested, transformer: droppable());
    on<CsvImportConfirmed>(_onConfirmed, transformer: droppable());
  }

  final CsvTransferRepository _repository;

  Future<void> _onFileRequested(
    CsvImportEvent event,
    Emitter<CsvImportState> emit,
  ) async {
    final previous = state.file;
    emit(CsvImportState(file: previous));
    try {
      final file = await _repository.chooseFile();
      // Closing the picker keeps the file that was chosen before.
      final chosen = file ?? previous;
      emit(
        CsvImportState(
          status: chosen == null
              ? CsvImportStatus.noFile
              : CsvImportStatus.ready,
          file: chosen,
        ),
      );
    } on NoConnectionException {
      emit(
        CsvImportState(
          status: CsvImportStatus.noConnection,
          file: previous,
          failedAction: event,
        ),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        CsvImportState(
          status: CsvImportStatus.failure,
          file: previous,
          failedAction: event,
        ),
      );
    }
  }

  Future<void> _onConfirmed(
    CsvImportConfirmed event,
    Emitter<CsvImportState> emit,
  ) async {
    final file = state.file;
    // Also from a failure: Try again imports the same file again.
    final canImport = switch (state.status) {
      CsvImportStatus.ready ||
      CsvImportStatus.noConnection ||
      CsvImportStatus.failure => true,
      _ => false,
    };
    if (file == null || !canImport) return;
    emit(CsvImportState(status: CsvImportStatus.importing, file: file));
    try {
      final result = await _repository.import(file);
      emit(state.copyWith(status: CsvImportStatus.imported, result: result));
    } on NoConnectionException {
      emit(
        state.copyWith(
          status: CsvImportStatus.noConnection,
          failedAction: event,
        ),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(status: CsvImportStatus.failure, failedAction: event),
      );
    }
  }
}
