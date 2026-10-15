part of 'salary_history_bloc.dart';

enum SalaryHistoryStatus {
  /// The saved months are being loaded.
  loading,

  /// The saved months are shown, or none was saved yet.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class SalaryHistoryState extends Equatable {
  const new({
    required this.newMonth,
    this.status = SalaryHistoryStatus.loading,
    this.entries = const [],
  });

  final SalaryHistoryStatus status;

  /// The saved months, the newest first.
  final List<SalaryHistoryEntry> entries;

  /// The month a new one starts with: the latest, up to the month of today,
  /// that has no saved salary.
  final YearMonth newMonth;

  /// Whether the account has no saved month.
  bool get isEmpty => entries.isEmpty;

  SalaryHistoryState copyWith({
    SalaryHistoryStatus? status,
    List<SalaryHistoryEntry>? entries,
    YearMonth? newMonth,
  }) {
    return SalaryHistoryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      newMonth: newMonth ?? this.newMonth,
    );
  }

  @override
  List<Object> get props => [status, entries, newMonth];
}
