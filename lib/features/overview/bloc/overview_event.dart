part of 'overview_bloc.dart';

sealed class OverviewEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The Overview opened: load the month of today.
final class OverviewStarted extends OverviewEvent {
  const new();
}

/// The user pressed an arrow of the month switcher.
final class MonthStepped extends OverviewEvent {
  const new({required this.forward});

  /// `true` for the next month, `false` for the previous one.
  final bool forward;

  @override
  List<Object> get props => [forward];
}

/// The user chose the whole month or one of its parts.
final class PeriodScopeSelected extends OverviewEvent {
  const new(this.scope);

  final PeriodScope scope;

  @override
  List<Object> get props => [scope];
}

/// The user pressed Try again.
final class OverviewRetried extends OverviewEvent {
  const new();
}

/// What the overview is made of may have changed: load the month again.
final class OverviewDataChanged extends OverviewEvent {
  const new();
}
