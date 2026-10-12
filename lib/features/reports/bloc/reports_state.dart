part of 'reports_bloc.dart';

/// The three views of the Reports screen.
enum ReportsView { categories, monthVsMonth, debts }

enum ReportsStatus {
  /// The reports are being loaded.
  loading,

  /// The reports are shown.
  ready,

  /// The account has no data to report.
  empty,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class ReportsState extends Equatable {
  const new({
    required this.month,
    this.status = ReportsStatus.loading,
    this.view = ReportsView.categories,
    this.scope = PeriodScope.month,
    this.comparedWith,
    this.report,
    this.previousReport,
    this.debts,
  });

  final ReportsStatus status;

  /// The month shown, or being loaded.
  final YearMonth month;
  final ReportsView view;

  /// The whole month or one of its parts.
  final PeriodScope scope;

  /// The report of [month].
  final MonthReport? report;

  /// The month the person chose to compare [month] with, or `null` for the
  /// month before it.
  final YearMonth? comparedWith;

  /// The month [month] is compared with: the one the person chose, or else
  /// the month before it.
  YearMonth get compareMonth => comparedWith ?? month.previous;

  /// The report of [compareMonth], or `null` when there is none.
  final MonthReport? previousReport;

  final DebtsReport? debts;

  /// Whether the salary is paid in two payments, so the parts can be chosen.
  bool get twoPayments => report?.hasParts ?? false;

  /// The scope that is shown: a part only for two payments.
  PeriodScope get effectiveScope => twoPayments ? scope : PeriodScope.month;

  /// The period of [month] that is shown.
  PeriodReport? get period => report?.reportOf(effectiveScope);

  /// The same period of [compareMonth].
  PeriodReport? get previousPeriod => previousReport?.reportOf(effectiveScope);

  /// How much more (positive) or less (negative) was spent than in the same
  /// period of [compareMonth], or `null` when it has no report.
  Money? get spentChange {
    final current = period;
    final previous = previousPeriod;
    if (current == null || previous == null) return null;
    return current.spent - previous.spent;
  }

  ReportsState copyWith({
    ReportsStatus? status,
    YearMonth? month,
    ReportsView? view,
    PeriodScope? scope,
    YearMonth? comparedWith,
    MonthReport? report,
    MonthReport? previousReport,
    DebtsReport? debts,
    bool clearReports = false,
  }) {
    return ReportsState(
      status: status ?? this.status,
      month: month ?? this.month,
      view: view ?? this.view,
      scope: scope ?? this.scope,
      comparedWith: comparedWith ?? this.comparedWith,
      report: clearReports ? null : report ?? this.report,
      previousReport: clearReports
          ? null
          : previousReport ?? this.previousReport,
      debts: clearReports ? null : debts ?? this.debts,
    );
  }

  @override
  List<Object?> get props => [
    status,
    month,
    view,
    scope,
    comparedWith,
    report,
    previousReport,
    debts,
  ];
}
