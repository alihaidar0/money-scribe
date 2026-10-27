import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

part 'csv_export_event.dart';
part 'csv_export_state.dart';

/// The Export CSV sheet: what to export and for which days. Export hands the
/// choice to the password dialog, which makes the file.
class CsvExportBloc extends Bloc<CsvExportEvent, CsvExportState> {
  new({required this._now}) : super(const CsvExportState()) {
    on<CsvKindToggled>(_onKindToggled, transformer: sequential());
    on<CsvKindsToggled>(_onKindsToggled, transformer: sequential());
    on<CsvPeriodSelected>(_onPeriodSelected, transformer: sequential());
    on<CsvDatesChosen>(_onDatesChosen, transformer: sequential());
    on<CsvExportRequested>(_onExportRequested, transformer: droppable());
  }

  final DateTime Function() _now;

  void _onKindToggled(CsvKindToggled event, Emitter<CsvExportState> emit) {
    final kinds = {...state.kinds};
    if (!kinds.remove(event.kind)) kinds.add(event.kind);
    emit(state.copyWith(status: CsvExportStatus.editing, kinds: kinds));
  }

  void _onKindsToggled(CsvKindsToggled event, Emitter<CsvExportState> emit) {
    final kinds = {...state.kinds};
    if (kinds.containsAll(event.kinds)) {
      kinds.removeAll(event.kinds);
    } else {
      kinds.addAll(event.kinds);
    }
    emit(state.copyWith(status: CsvExportStatus.editing, kinds: kinds));
  }

  void _onPeriodSelected(
    CsvPeriodSelected event,
    Emitter<CsvExportState> emit,
  ) {
    emit(state.copyWith(status: CsvExportStatus.editing, period: event.period));
  }

  void _onDatesChosen(CsvDatesChosen event, Emitter<CsvExportState> emit) {
    emit(
      CsvExportState(
        kinds: state.kinds,
        period: state.period,
        from: event.from,
        to: event.to,
      ),
    );
  }

  void _onExportRequested(
    CsvExportRequested event,
    Emitter<CsvExportState> emit,
  ) {
    if (!state.canExport) return;
    emit(
      CsvExportState(
        status: CsvExportStatus.chosen,
        kinds: state.kinds,
        period: state.period,
        from: state.from,
        to: state.to,
        request: _request(),
      ),
    );
  }

  CsvExportRequest _request() {
    final year = _now().year;
    return switch (state.period) {
      CsvPeriod.allTime => CsvExportRequest(
        kinds: state.kinds,
        period: CsvPeriod.allTime,
      ),
      CsvPeriod.thisYear => CsvExportRequest(
        kinds: state.kinds,
        period: CsvPeriod.thisYear,
        from: DateTime(year),
        to: DateTime(year, 12, 31),
      ),
      CsvPeriod.custom => CsvExportRequest(
        kinds: state.kinds,
        period: CsvPeriod.custom,
        from: state.from,
        to: state.to,
      ),
    };
  }
}
