import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/debt_badges.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/features/debts/bloc/debts_bloc.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';

/// DB-1 and DB-9 to DB-12: the debts, with what is owed to the person and what
/// they owe, filtered by lent or borrowed. A card opens the debt.
class DebtsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DebtsBloc(
        repository: context.read<DebtsRepository>(),
        now: context.read<Clock>().now,
      )..add(const DebtsStarted()),
      child: const _DebtsView(),
    );
  }
}

/// Opens the form that adds a debt, and shows what it did when it closes.
Future<void> _addDebt(BuildContext context) async {
  final bloc = context.read<DebtsBloc>();
  await context.push<void>(AppRoutes.addDebt);
  bloc.add(const DebtsRefreshed());
}

/// Opens the debt [id], and shows what was done to it when it closes.
Future<void> _openDebt(BuildContext context, String id) async {
  final bloc = context.read<DebtsBloc>();
  await context.push<void>(AppRoutes.debtDetailsPath(id));
  bloc.add(const DebtsRefreshed());
}

class _DebtsView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<DebtsBloc>();
    final showAdd = context.select<DebtsBloc, bool>(
      (bloc) =>
          bloc.state.status == DebtsStatus.ready && bloc.state.debts.isNotEmpty,
    );
    final status = context.select<DebtsBloc, DebtsStatus>(
      (bloc) => bloc.state.status,
    );
    final isEmpty = context.select<DebtsBloc, bool>(
      (bloc) => bloc.state.debts.isEmpty,
    );

    return TopLevelScreen(
      title: l10n.debtsTitle,
      floatingActionButton: showAdd
          ? FloatingActionButton.extended(
              onPressed: () => _addDebt(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addDebtAction),
            )
          : null,
      body: switch (status) {
        DebtsStatus.loading => const _Skeleton(),
        DebtsStatus.noConnection => FailureView(
          kind: FailureKind.noConnection,
          onRetry: () => bloc.add(const DebtsRetried()),
        ),
        DebtsStatus.failure => FailureView(
          kind: FailureKind.error,
          errorTitle: l10n.debtsLoadFailed,
          onRetry: () => bloc.add(const DebtsRetried()),
        ),
        DebtsStatus.ready when isEmpty => StateView(
          icon: Icons.handshake_outlined,
          title: l10n.debtsEmptyTitle,
          actionLabel: l10n.addADebtAction,
          filledAction: true,
          onAction: () => _addDebt(context),
        ),
        DebtsStatus.ready => const _Content(),
      },
    );
  }
}

/// The widest the list grows, so a card stays readable on a wide screen.
const _maxContentWidth = 720.0;

class _Content extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DebtsBloc>().state;
    final shown = state.shown;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          // Room under the last card for the button.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            _SummaryRow(owedToYou: state.owedToYou, youOwe: state.youOwe),
            const SizedBox(height: 16),
            const _FilterSwitch(),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  context.l10n.noDebtsOfKind,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final debt in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DebtCard(debt: debt, today: state.today),
                ),
          ],
        ),
      ),
    );
  }
}

/// "Owed to you" and "You owe", side by side while there is room.
class _SummaryRow extends StatelessWidget {
  const new({required this.owedToYou, required this.youOwe});

  final Money owedToYou;
  final Money youOwe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final owed = _SummaryTile(label: l10n.summaryOwedToYou, amount: owedToYou);
    final owe = _SummaryTile(label: l10n.summaryYouOwe, amount: youOwe);

    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= 360 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3
          ? Row(
              children: [
                Expanded(child: owed),
                const SizedBox(width: 12),
                Expanded(child: owe),
              ],
            )
          : Column(children: [owed, const SizedBox(height: 12), owe]),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const new({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.moneyFormatter.format(amount),
              style: theme.textTheme.titleLarge?.amount,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSwitch extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = context.select<DebtsBloc, DebtsFilter>(
      (bloc) => bloc.state.filter,
    );

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<DebtsFilter>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: DebtsFilter.all, label: Text(l10n.filterAll)),
          ButtonSegment(value: DebtsFilter.lent, label: Text(l10n.debtLent)),
          ButtonSegment(
            value: DebtsFilter.borrowed,
            label: Text(l10n.debtBorrowed),
          ),
        ],
        selected: {filter},
        onSelectionChanged: (selection) =>
            context.read<DebtsBloc>().add(DebtsFilterSelected(selection.first)),
      ),
    );
  }
}

/// One debt: the person and whether it was lent or borrowed, what is left to
/// repay, what it was, its due day and where it stands.
class _DebtCard extends StatelessWidget {
  const new({required this.debt, required this.today});

  final Debt debt;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatter = context.moneyFormatter;
    final colors = context.moneyColors;
    final status = debt.statusOn(today);
    final due = debt.dueDate;
    final lent = debt.direction == DebtDirection.lent;
    final summary = lent
        ? l10n.debtLentSummary(
            amount: formatter.format(debt.amount),
            repaid: formatter.format(debt.repaid),
          )
        : l10n.debtBorrowedSummary(
            amount: formatter.format(debt.amount),
            repaid: formatter.format(debt.repaid),
          );

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDebt(context, debt.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(debt.person, style: theme.textTheme.titleMedium),
                    DirectionBadge(debt.direction),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatter.format(debt.remaining),
                  style: theme.textTheme.headlineSmall?.amount.copyWith(
                    color: status == DebtStatus.settled
                        ? theme.colorScheme.onSurfaceVariant
                        : lent
                        ? colors.lent.color
                        : colors.borrowed.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (due != null)
                      Text(
                        l10n.debtDue(
                          date: context.dayFormatter.formatDate(
                            due,
                            today: today,
                          ),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    StatusBadge(status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SkeletonBox(height: 80),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonBox(height: 140),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
