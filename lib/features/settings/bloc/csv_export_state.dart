part of 'csv_export_bloc.dart';

enum CsvExportStatus {
  /// The person is choosing what to export.
  editing,

  /// The person pressed Export: [CsvExportState.request] goes to the password
  /// dialog.
  chosen,
}

final class CsvExportState extends Equatable {
  const new({
    this.status = CsvExportStatus.editing,
    this.kinds = const {
      CsvDataKind.accounts,
      CsvDataKind.categories,
      CsvDataKind.transactions,
      CsvDataKind.debts,
      CsvDataKind.salaryMonths,
    },
    this.period = CsvPeriod.allTime,
    this.from,
    this.to,
    this.request,
  });

  final CsvExportStatus status;

  /// The kinds of data to export.
  final Set<CsvDataKind> kinds;
  final CsvPeriod period;

  /// The first and the last day of a custom period.
  final DateTime? from;
  final DateTime? to;

  /// What to export, once [status] is `chosen`: "this year" as its days.
  final CsvExportRequest? request;

  /// Whether the choices make an export: something to export, and for a
  /// custom period both days with the first not after the last.
  bool get canExport {
    if (kinds.isEmpty) return false;
    if (period != CsvPeriod.custom) return true;
    final from = this.from;
    final to = this.to;
    return from != null && to != null && !from.isAfter(to);
  }

  /// Whether the custom period has both days and they are the wrong way round.
  bool get hasReversedDates {
    final from = this.from;
    final to = this.to;
    return period == CsvPeriod.custom &&
        from != null &&
        to != null &&
        from.isAfter(to);
  }

  CsvExportState copyWith({
    CsvExportStatus? status,
    Set<CsvDataKind>? kinds,
    CsvPeriod? period,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
  }) {
    return CsvExportState(
      status: status ?? this.status,
      kinds: kinds ?? this.kinds,
      period: period ?? this.period,
      from: clearDates ? null : from ?? this.from,
      to: clearDates ? null : to ?? this.to,
    );
  }

  @override
  List<Object?> get props => [status, kinds, period, from, to, request];
}
