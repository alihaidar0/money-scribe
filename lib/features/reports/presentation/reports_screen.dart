import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/month_picker_sheet.dart';
import 'package:money_scribe/core/widgets/part_selector.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/features/reports/bloc/reports_bloc.dart';
import 'package:money_scribe/features/reports/domain/reports_repository.dart';
import 'package:money_scribe/features/reports/presentation/widgets/categories_view.dart';
import 'package:money_scribe/features/reports/presentation/widgets/debts_view.dart';
import 'package:money_scribe/features/reports/presentation/widgets/month_comparison_view.dart';
import 'package:money_scribe/features/reports/presentation/widgets/parts_summary.dart';

/// RP-1 to RP-9: the Reports screen. Three views, chosen with the segments at
/// the top: the spending by category, a month against the month before, and
/// where the debts stand. For two payments a month, the whole month or one
/// part can be chosen.
class ReportsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportsBloc(
        repository: context.read<ReportsRepository>(),
        now: context.read<Clock>().now,
      )..add(const ReportsStarted()),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ReportsBloc>();
    final status = context.select<ReportsBloc, ReportsStatus>(
      (bloc) => bloc.state.status,
    );

    return TopLevelScreen(
      title: l10n.reportsTitle,
      body: switch (status) {
        ReportsStatus.loading => const _Skeleton(),
        ReportsStatus.noConnection => FailureView(
          kind: FailureKind.noConnection,
          onRetry: () => bloc.add(const ReportsRetried()),
        ),
        ReportsStatus.failure => FailureView(
          kind: FailureKind.error,
          errorTitle: l10n.reportsLoadFailed,
          onRetry: () => bloc.add(const ReportsRetried()),
        ),
        ReportsStatus.empty => StateView(
          icon: Icons.bar_chart_outlined,
          title: l10n.reportsEmptyTitle,
          message: l10n.reportsEmptyMessage,
          actionLabel: l10n.reportsEmptyAction,
          filledAction: true,
          onAction: () => context.push<void>(AppRoutes.addTransaction),
        ),
        ReportsStatus.ready => const _Content(),
      },
    );
  }
}

/// The widest the page grows, so it stays readable on a wide screen.
const _maxContentWidth = 720.0;

class _Content extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ReportsBloc>().state;
    final bloc = context.read<ReportsBloc>();
    final view = state.view;
    final period = state.period;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            _ViewSwitch(
              selected: view,
              onSelected: (view) => bloc.add(ReportsViewSelected(view)),
            ),
            if (view != ReportsView.debts) ...[
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MonthChip(
                  month: state.month,
                  onPressed: () => _chooseMonth(context, state.month),
                ),
              ),
              if (view == ReportsView.monthVsMonth) ...[
                const SizedBox(height: 12),
                _CompareChip(
                  month: state.compareMonth,
                  onPressed: () => _chooseCompareMonth(context, state),
                ),
              ],
              if (state.twoPayments) ...[
                const SizedBox(height: 12),
                PartSelector(
                  selected: state.effectiveScope,
                  onSelected: (scope) => bloc.add(ReportsScopeSelected(scope)),
                ),
              ],
            ],
            const SizedBox(height: 24),
            switch (view) {
              ReportsView.categories when period != null => CategoriesView(
                period: period,
                month: state.month,
                scope: state.effectiveScope,
                spentChange: state.spentChange,
                comparedMonth: state.compareMonth,
                parts: _partsOf(state),
                onPartSelected: (scope) =>
                    bloc.add(ReportsScopeSelected(scope)),
              ),
              ReportsView.monthVsMonth when period != null =>
                MonthComparisonView(
                  month: state.month,
                  comparedMonth: state.compareMonth,
                  scope: state.effectiveScope,
                  current: period,
                  previous: state.previousPeriod,
                  parts: _partsOf(state),
                  onPartSelected: (scope) =>
                      bloc.add(ReportsScopeSelected(scope)),
                ),
              ReportsView.debts when state.debts != null => DebtsView(
                report: state.debts!,
                today: context.read<Clock>().now(),
              ),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }

  /// The two parts of the whole month, for a month paid in two payments; `null`
  /// when one part is shown already.
  PartsReports? _partsOf(ReportsState state) {
    final report = state.report;
    if (report == null ||
        !state.twoPayments ||
        state.effectiveScope != PeriodScope.month) {
      return null;
    }
    final previous = state.previousReport;
    return PartsReports(
      first: report.firstPart!,
      second: report.secondPart!,
      previousFirst: previous?.firstPart,
      previousSecond: previous?.secondPart,
    );
  }

  /// Opens the month picker, up to the month of today.
  Future<void> _chooseMonth(BuildContext context, YearMonth selected) async {
    final bloc = context.read<ReportsBloc>();
    final last = YearMonth.fromDate(context.read<Clock>().now());
    final month = await showMonthPickerSheet(
      context,
      selected: selected,
      last: last,
    );
    if (month != null) bloc.add(ReportsMonthSelected(month));
  }

  /// Opens the month picker for the month to compare with.
  Future<void> _chooseCompareMonth(
    BuildContext context,
    ReportsState state,
  ) async {
    final bloc = context.read<ReportsBloc>();
    final last = YearMonth.fromDate(context.read<Clock>().now());
    final month = await showMonthPickerSheet(
      context,
      selected: state.compareMonth,
      last: last,
    );
    if (month != null) bloc.add(ReportsCompareMonthSelected(month));
  }
}

/// The chip that chooses the month the comparison is made against, with a
/// small label above it.
class _CompareChip extends StatelessWidget {
  const new({required this.month, required this.onPressed});

  final YearMonth month;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportsCompareWith,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        MonthChip(
          month: month,
          onPressed: onPressed,
          semanticLabel: l10n.reportsCompareChipLabel(
            month: context.monthFormatter.format(month),
          ),
        ),
      ],
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  const new({required this.selected, required this.onSelected});

  final ReportsView selected;
  final ValueChanged<ReportsView> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: PillSegmentedButton<ReportsView>(
        segments: [
          ButtonSegment(
            value: ReportsView.categories,
            label: Text(l10n.reportsViewCategories),
          ),
          ButtonSegment(
            value: ReportsView.monthVsMonth,
            label: Text(l10n.reportsViewMonthVsMonth),
          ),
          ButtonSegment(
            value: ReportsView.debts,
            label: Text(l10n.reportsViewDebts),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}

/// The shape of the page while it loads: the segments, a ring and five rows.
class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SkeletonBox(height: 40, radius: 20),
          const SizedBox(height: 24),
          const Center(
            child: SkeletonBox(height: 200, width: 200, radius: 100),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < 5; i++) ...[
            const SkeletonBox(height: 56),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
