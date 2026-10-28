import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/currency_notice.dart';
import 'package:money_scribe/core/widgets/debt_badges.dart';
import 'package:money_scribe/core/widgets/debt_summary_row.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/pull_to_refresh.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/core/widgets/wide_frame.dart';
import 'package:money_scribe/features/debts/bloc/debts_bloc.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';
import 'package:money_scribe/features/debts/presentation/widgets/debt_detail_content.dart';

/// DB-1 and DB-9 to DB-12: the debts, with what is owed to the person and what
/// they owe, filtered by lent or borrowed. A card opens the debt; on a wide
/// window it shows the debt in a pane beside the list instead.
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

/// Opens the debt [id] with the sheet that adds a repayment over it.
Future<void> _addRepayment(BuildContext context, String id) async {
  final bloc = context.read<DebtsBloc>();
  await context.push<void>(AppRoutes.debtDetailsPath(id, addRepayment: true));
  bloc.add(const DebtsRefreshed());
}

/// Opens the form that changes the debt [id].
Future<void> _editDebt(BuildContext context, String id) async {
  final bloc = context.read<DebtsBloc>();
  await context.push<void>(AppRoutes.editDebtPath(id));
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

    return BlocListener<DebtsBloc, DebtsState>(
      listenWhen: (previous, current) =>
          previous.deleteStatus != current.deleteStatus &&
          (current.deleteStatus == DebtsDeleteStatus.failed ||
              current.deleteStatus == DebtsDeleteStatus.stale),
      listener: (context, state) {
        if (state.deleteStatus == DebtsDeleteStatus.stale) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.debtChangedElsewhere)));
          return;
        }
        final id = state.deletingId;
        if (id == null) return;
        showFailureSnackBar(
          context,
          l10n.couldNotDelete,
          onRetry: () => bloc.add(DebtDeleteConfirmed(id)),
        );
      },
      child: _screen(context, showAdd, status, isEmpty),
    );
  }

  Widget _screen(
    BuildContext context,
    bool showAdd,
    DebtsStatus status,
    bool isEmpty,
  ) {
    final l10n = context.l10n;
    final bloc = context.read<DebtsBloc>();

    return TopLevelScreen(
      title: l10n.debtsTitle,
      floatingActionButton: showAdd
          ? FloatingActionButton.extended(
              heroTag: null,
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

/// The content width from which the list and the detail of the chosen debt sit
/// side by side (the expanded window size class).
const _detailPaneFrom = 840.0;

class _Content extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _detailPaneFrom) {
          return const Row(
            children: [
              Expanded(flex: 5, child: _ListPane(wide: true)),
              VerticalDivider(width: 1),
              Expanded(flex: 4, child: _DetailPane()),
            ],
          );
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: FrameWidth.regular.value),
            child: const _ListPane(wide: false),
          ),
        );
      },
    );
  }
}

/// The totals, the filter and the cards. With [wide], a card shows its debt in
/// the detail pane instead of opening it.
class _ListPane extends StatelessWidget {
  const new({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DebtsBloc>().state;
    final shown = state.shown;
    final selectedId = wide ? state.selected?.id : null;

    return PullToRefresh(
      onRefresh: (done) =>
          context.read<DebtsBloc>().add(DebtsRefreshed(done: done)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Room under the last card for the button.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          DebtSummaryRow(owedToYou: state.owedToYou, youOwe: state.youOwe),
          if (state.hasOtherCurrencies)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CurrencyNotice(context.l10n.debtsOtherCurrenciesNotice),
            ),
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
                child: _DebtCard(
                  debt: debt,
                  today: state.today,
                  selected: debt.id == selectedId,
                  onTap: wide
                      ? () =>
                            context.read<DebtsBloc>().add(DebtSelected(debt.id))
                      : () => _openDebt(context, debt.id),
                ),
              ),
        ],
      ),
    );
  }
}

/// DB-3 on a wide window: everything about the chosen debt, with the buttons
/// that add a repayment, change and delete it.
class _DetailPane extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<DebtsBloc>().state;
    final debt = state.selected;
    if (debt == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final deleting = state.deleteStatus == DebtsDeleteStatus.deleting;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DebtDetailContent(
          debt: debt,
          today: state.today,
          onEditRepayment: (_) => _openDebt(context, debt.id),
          footer: [
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (!debt.isSettled)
                  FilledButton.icon(
                    onPressed: () => _addRepayment(context, debt.id),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addRepaymentAction),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => _editDebt(context, debt.id),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.editAction),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: deleting ? null : () => _delete(context, debt),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Debt debt) async {
    final bloc = context.read<DebtsBloc>();
    final l10n = context.l10n;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteDebtTitle,
      message: l10n.deleteDebtMessage(person: debt.person),
    );
    if (confirmed) bloc.add(DebtDeleteConfirmed(debt.id));
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
      child: PillSegmentedButton<DebtsFilter>(
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
  const new({
    required this.debt,
    required this.today,
    required this.selected,
    required this.onTap,
  });

  final Debt debt;
  final DateTime today;

  /// Whether the detail pane shows this debt.
  final bool selected;
  final VoidCallback onTap;

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
      selected: selected,
      child: Material(
        color: selected
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
