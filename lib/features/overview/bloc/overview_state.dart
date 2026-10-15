part of 'overview_bloc.dart';

enum OverviewStatus {
  /// The month is being loaded.
  loading,

  /// The month is shown.
  ready,

  /// The account has no data yet.
  firstLaunch,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class OverviewState extends Equatable {
  const new({
    required this.month,
    this.status = OverviewStatus.loading,
    this.scope = PeriodScope.month,
    this.canStepForward = false,
    this.overview,
  });

  final OverviewStatus status;

  /// The month shown, or being loaded.
  final YearMonth month;

  /// The whole month or one of its parts.
  final PeriodScope scope;

  /// Whether there is a next month to go to: not past the month of today.
  final bool canStepForward;

  final MonthOverview? overview;

  /// The figures to show: those of the chosen [scope], or `null` until the
  /// month is loaded.
  OverviewFigures? get figures => overview?.figuresOf(scope);

  OverviewState copyWith({
    OverviewStatus? status,
    YearMonth? month,
    PeriodScope? scope,
    bool? canStepForward,
    MonthOverview? overview,
    bool clearOverview = false,
  }) {
    return OverviewState(
      status: status ?? this.status,
      month: month ?? this.month,
      scope: scope ?? this.scope,
      canStepForward: canStepForward ?? this.canStepForward,
      overview: clearOverview ? null : overview ?? this.overview,
    );
  }

  @override
  List<Object?> get props => [status, month, scope, canStepForward, overview];
}
