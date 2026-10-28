import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/amount_row.dart';
import 'package:money_scribe/core/widgets/bar_clearance.dart';
import 'package:money_scribe/core/widgets/currency_notice.dart';
import 'package:money_scribe/core/widgets/hero_card.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/part_dates_label.dart';
import 'package:money_scribe/core/widgets/part_selector.dart';
import 'package:money_scribe/core/widgets/period_range_caption.dart';
import 'package:money_scribe/core/widgets/pull_to_refresh.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/features/overview/bloc/overview_bloc.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';
import 'package:money_scribe/features/overview/presentation/widgets/debt_choice_sheet.dart';
import 'package:money_scribe/features/overview/presentation/widgets/month_switcher.dart';
import 'package:money_scribe/features/overview/presentation/widgets/period_card.dart';

/// OV-1, OV-2, OV-3 and their loading, error and no-connection states: the
/// balance of a month and where it comes from.
class OverviewScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OverviewBloc(
        repository: context.read<OverviewRepository>(),
        now: context.read<Clock>().now,
      )..add(const OverviewStarted()),
      child: const _OverviewView(),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OverviewBloc>();

    return TopLevelScreen(
      title: context.l10n.overviewTitle,
      body: BlocBuilder<OverviewBloc, OverviewState>(
        builder: (context, state) => switch (state.status) {
          OverviewStatus.loading => const _OverviewSkeleton(),
          OverviewStatus.firstLaunch => _FirstLaunch(state: state),
          OverviewStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const OverviewRetried()),
          ),
          OverviewStatus.failure => FailureView(
            kind: FailureKind.error,
            onRetry: () => bloc.add(const OverviewRetried()),
          ),
          OverviewStatus.ready => _OverviewContent(state: state),
        },
      ),
    );
  }
}

/// The content width from which the rows go into a second column.
const _twoColumnsFrom = 720.0;

class _OverviewContent extends StatelessWidget {
  const new({required this.state});

  final OverviewState state;

  @override
  Widget build(BuildContext context) {
    final overview = state.overview!;
    final figures = state.figures!;
    final firstPart = overview.firstPart;
    final secondPart = overview.secondPart;
    final l10n = context.l10n;
    final bloc = context.read<OverviewBloc>();
    final formatter = context.moneyFormatter;

    final summary = <Widget>[
      MonthSwitcher(
        month: state.month,
        canStepForward: state.canStepForward,
        onPrevious: () => bloc.add(const MonthStepped(forward: false)),
        onNext: () => bloc.add(const MonthStepped(forward: true)),
      ),
      const SizedBox(height: 16),
      if (overview.hasParts) ...[
        PartSelector(
          selected: state.scope,
          onSelected: (scope) => bloc.add(PeriodScopeSelected(scope)),
        ),
        const SizedBox(height: 8),
        PeriodRangeCaption(
          range: overview.rangeOf(state.scope),
          today: context.read<Clock>().now(),
        ),
        const SizedBox(height: 16),
      ],
      HeroCard(
        label: l10n.overviewBalance,
        amount: _balance(formatter.format, formatter.formatSigned, figures),
        details: [
          HeroDetail(
            label: l10n.overviewIncome,
            amount: formatter.formatSigned(figures.income),
          ),
          HeroDetail(
            label: l10n.overviewSpent,
            amount: formatter.formatSigned(figures.spent),
          ),
        ],
      ),
      if (overview.hasOtherCurrencies) ...[
        const SizedBox(height: 8),
        CurrencyNotice(l10n.recordsInOtherCurrenciesNotice),
      ],
      const SizedBox(height: 16),
      const _Actions(),
      if (firstPart != null &&
          secondPart != null &&
          state.scope == PeriodScope.month) ...[
        const SizedBox(height: 16),
        PeriodCard(
          title: partDatesLabel(
            context,
            part: PeriodScope.firstPart,
            range: overview.rangeOf(PeriodScope.firstPart),
            today: context.read<Clock>().now(),
          ),
          figures: firstPart,
          onTap: () => context.go(AppRoutes.transactions),
        ),
        const SizedBox(height: 12),
        PeriodCard(
          title: partDatesLabel(
            context,
            part: PeriodScope.secondPart,
            range: overview.rangeOf(PeriodScope.secondPart),
            today: context.read<Clock>().now(),
          ),
          figures: secondPart,
          onTap: () => context.go(AppRoutes.transactions),
        ),
      ],
    ];
    final rows = _rows(context, figures);

    // Pulling a list down at the top loads the figures again.
    Widget refreshable(List<Widget> children, {EdgeInsets? padding}) {
      return PullToRefresh(
        onRefresh: (done) => bloc.add(OverviewRefreshed(done: done)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding?.withBarClearance(context),
          children: children,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _twoColumnsFrom) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: refreshable(summary)),
                const SizedBox(width: 16),
                Expanded(child: refreshable(rows)),
              ],
            ),
          );
        }
        return refreshable([
          ...summary,
          const SizedBox(height: 16),
          ...rows,
        ], padding: const EdgeInsets.all(16));
      },
    );
  }

  /// The balance, with a true minus sign when it is below zero.
  String _balance(
    String Function(Money) plain,
    String Function(Money) signed,
    OverviewFigures figures,
  ) {
    return figures.balance.isNegative
        ? signed(figures.balance)
        : plain(figures.balance);
  }

  List<Widget> _rows(BuildContext context, OverviewFigures figures) {
    final l10n = context.l10n;

    return [
      AmountRow(
        icon: LucideIcons.banknote,
        title: l10n.salaryTitle,
        amount: figures.salary,
        onTap: () => context.go(AppRoutes.salary),
      ),
      const SizedBox(height: 8),
      AmountRow(
        icon: LucideIcons.refreshCw,
        title: l10n.overviewRecurringIncome,
        amount: figures.recurringIncome,
        onTap: () => context.go(AppRoutes.fixedItems),
      ),
      const SizedBox(height: 8),
      AmountRow(
        icon: LucideIcons.piggyBank,
        title: l10n.overviewOtherIncome,
        amount: figures.otherIncome,
        onTap: () => context.go(AppRoutes.transactions),
      ),
      const SizedBox(height: 8),
      AmountRow(
        icon: LucideIcons.house,
        title: l10n.overviewFixedCosts,
        amount: figures.fixedCosts,
        onTap: () => context.go(AppRoutes.fixedItems),
      ),
      const SizedBox(height: 8),
      AmountRow(
        icon: LucideIcons.shoppingBag,
        title: l10n.overviewPurchases,
        amount: figures.purchases,
        onTap: () => context.go(AppRoutes.transactions),
      ),
      const SizedBox(height: 8),
      AmountRow(
        icon: LucideIcons.handshake,
        title: l10n.overviewDebtMovements,
        amount: figures.debtMovements,
        onTap: () => context.go(AppRoutes.debts),
      ),
    ];
  }
}

/// "Add purchase" and "Add repayment", side by side.
class _Actions extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => context.push(AppRoutes.addTransaction),
              child: Text(
                l10n.overviewAddPurchase,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => _addRepayment(context),
              child: Text(
                l10n.overviewAddRepayment,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addRepayment(BuildContext context) async {
    final debt = await showDebtChoiceSheet(context);
    if (debt == null || !context.mounted) return;
    // The debt opens with the sheet that adds the repayment over it.
    await context.push<void>(
      AppRoutes.debtDetailsPath(debt.id, addRepayment: true),
    );
  }
}

/// OV-3: the Overview of an account with no data yet.
class _FirstLaunch extends StatelessWidget {
  const new({required this.state});

  final OverviewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<OverviewBloc>();

    return Column(
      children: [
        // A month with nothing in it can be left for another month.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: MonthSwitcher(
            month: state.month,
            canStepForward: state.canStepForward,
            onPrevious: () => bloc.add(const MonthStepped(forward: false)),
            onNext: () => bloc.add(const MonthStepped(forward: true)),
          ),
        ),
        Expanded(child: _firstLaunchContent(context, l10n, theme)),
      ],
    );
  }

  Widget _firstLaunchContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconCircle(icon: LucideIcons.wallet, size: 112),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  l10n.firstLaunchTitle,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.firstLaunchMessage,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.salary),
                child: Text(
                  l10n.firstLaunchAction,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// OV-5: grey blocks where the content will be.
class _OverviewSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: SkeletonBox(height: 48, width: 220, radius: 100)),
          const SizedBox(height: 16),
          const SkeletonBox(height: 148),
          const SizedBox(height: 16),
          const SkeletonBox(height: 48, radius: 100),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++) ...[
            const SkeletonBox(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
