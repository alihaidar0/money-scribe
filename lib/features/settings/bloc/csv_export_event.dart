part of 'csv_export_bloc.dart';

sealed class CsvExportEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The user ticked or unticked a kind of data.
final class CsvKindToggled extends CsvExportEvent {
  const new(this.kind);

  final CsvDataKind kind;

  @override
  List<Object> get props => [kind];
}

/// The user ticked or unticked a chip that stands for several kinds at once
/// (Accounts and categories): all of them are ticked unless they all were.
final class CsvKindsToggled extends CsvExportEvent {
  const new(this.kinds);

  final Set<CsvDataKind> kinds;

  @override
  List<Object> get props => [kinds];
}

/// The user chose All time, This year or Custom.
final class CsvPeriodSelected extends CsvExportEvent {
  const new(this.period);

  final CsvPeriod period;

  @override
  List<Object> get props => [period];
}

/// The user chose the first and the last day of a custom period. A day
/// that is `null` is not chosen (yet).
final class CsvDatesChosen extends CsvExportEvent {
  const new({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  @override
  List<Object?> get props => [from, to];
}

/// The user pressed Export.
final class CsvExportRequested extends CsvExportEvent {
  const new();
}
