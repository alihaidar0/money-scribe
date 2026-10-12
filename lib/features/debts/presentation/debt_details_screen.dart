import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/leave_screen.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/debt_badges.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/debts/bloc/debt_details_bloc.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';
import 'package:money_scribe/features/debts/presentation/widgets/repayment_sheet.dart';

/// DB-3 to DB-7: one debt with its repayments. Repayments are added and
/// changed in a bottom sheet; the menu changes or deletes the debt, and every
/// deletion asks first. With [addRepayment] the sheet that adds a repayment
/// opens as soon as the debt is shown.
class DebtDetailsScreen extends StatelessWidget {
  const new({required this.id, this.addRepayment = false, super.key});

  final String id;
  final bool addRepayment;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DebtDetailsBloc(
        repository: context.read<DebtsRepository>(),
        id: id,
        now: context.read<Clock>().now,
      )..add(const DebtDetailsStarted()),
      child: _DebtDetailsView(addRepayment: addRepayment),
    );
  }
}

class _DebtDetailsView extends StatefulWidget {
  const new({required this.addRepayment});

  final bool addRepayment;

  @override
  State<_DebtDetailsView> createState() => _DebtDetailsViewState();
}

class _DebtDetailsViewState extends State<_DebtDetailsView> {
  /// Whether the sheet that adds a repayment is still to be opened.
  late bool _openRepaymentSheet = widget.addRepayment;

  Future<void> _addRepayment(BuildContext context) async {
    final bloc = context.read<DebtDetailsBloc>();
    final debt = bloc.state.debt;
    if (debt == null) return;
    final result = await showRepaymentSheet(
      context,
      currency: debt.amount.currency,
      maxAmount: debt.remaining,
      today: context.read<Clock>().now(),
    );
    if (result is RepaymentSheetSaved) bloc.add(RepaymentAdded(result.draft));
  }

  Future<void> _editRepayment(BuildContext context, Repayment repayment) async {
    final bloc = context.read<DebtDetailsBloc>();
    final debt = bloc.state.debt;
    if (debt == null) return;
    final result = await showRepaymentSheet(
      context,
      currency: debt.amount.currency,
      maxAmount: debt.remaining + repayment.amount,
      today: context.read<Clock>().now(),
      repayment: repayment,
    );
    switch (result) {
      case RepaymentSheetSaved(:final draft):
        bloc.add(RepaymentChanged(repayment.id, draft));
      case RepaymentSheetDeleted():
        bloc.add(RepaymentDeleted(repayment.id));
      case null:
        break;
    }
  }

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<DebtDetailsBloc>();
    await context.push<void>(AppRoutes.editDebtPath(bloc.state.debtId));
    bloc.add(const DebtDetailsRefreshed());
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<DebtDetailsBloc>();
    final debt = bloc.state.debt;
    if (debt == null) return;
    final l10n = context.l10n;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteDebtTitle,
      message: l10n.deleteDebtMessage(person: debt.person),
    );
    if (confirmed) bloc.add(const DebtDeleteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<DebtDetailsBloc>();

    return BlocListener<DebtDetailsBloc, DebtDetailsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.deleteStatus != current.deleteStatus ||
          previous.failedAction != current.failedAction,
      listener: (context, state) {
        if (state.status == DebtDetailsStatus.notFound ||
            state.deleteStatus == DebtDeleteStatus.deleted) {
          context.leave(fallback: AppRoutes.debts);
          return;
        }
        if (state.status == DebtDetailsStatus.ready && _openRepaymentSheet) {
          _openRepaymentSheet = false;
          unawaited(_addRepayment(context));
        }
        final action = state.failedAction;
        if (action != null) {
          showFailureSnackBar(
            context,
            action is RepaymentDeleted
                ? l10n.couldNotDelete
                : l10n.couldNotSave,
            onRetry: () => bloc.add(action),
          );
        }
        if (state.deleteStatus == DebtDeleteStatus.failed) {
          showFailureSnackBar(
            context,
            l10n.couldNotDelete,
            onRetry: () => bloc.add(const DebtDeleteRequested()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.debtDetailsTitle),
          actions: [
            BlocSelector<DebtDetailsBloc, DebtDetailsState, bool>(
              selector: (state) => state.status == DebtDetailsStatus.ready,
              builder: (context, ready) => ready
                  ? PopupMenuButton<_MenuAction>(
                      tooltip: MaterialLocalizations.of(context)
                          .showMenuTooltip,
                      onSelected: (action) => switch (action) {
                        _MenuAction.edit => _edit(context),
                        _MenuAction.delete => _delete(context),
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _MenuAction.edit,
                          child: Text(l10n.editAction),
                        ),
                        PopupMenuItem(
                          value: _MenuAction.delete,
                          child: Text(l10n.deleteAction),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        body: BlocBuilder<DebtDetailsBloc, DebtDetailsState>(
          builder: (context, state) => switch (state.status) {
            DebtDetailsStatus.loading ||
            DebtDetailsStatus.notFound => const _Skeleton(),
            DebtDetailsStatus.noConnection => FailureView(
              kind: FailureKind.noConnection,
              onRetry: () => bloc.add(const DebtDetailsRetried()),
            ),
            DebtDetailsStatus.failure => FailureView(
              kind: FailureKind.error,
              onRetry: () => bloc.add(const DebtDetailsRetried()),
            ),
            DebtDetailsStatus.ready => _Content(
              debt: state.debt!,
              today: state.today,
              onAddRepayment: () => _addRepayment(context),
              onEditRepayment: (repayment) =>
                  _editRepayment(context, repayment),
            ),
          },
        ),
      ),
    );
  }
}

enum _MenuAction { edit, delete }

/// The widest the content grows, so it stays readable on a wide screen.
const _maxContentWidth = 720.0;

class _Content extends StatelessWidget {
  const new({
    required this.debt,
    required this.today,
    required this.onAddRepayment,
    required this.onEditRepayment,
  });

  final Debt debt;
  final DateTime today;
  final VoidCallback onAddRepayment;
  final ValueChanged<Repayment> onEditRepayment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatter = context.moneyFormatter;
    final days = context.dayFormatter;
    final lent = debt.direction == DebtDirection.lent;
    final status = debt.statusOn(today);
    final due = debt.dueDate;

    Widget fact(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      debt.person,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lent
                        ? l10n.debtLentHeadline(
                            amount: formatter.format(debt.amount),
                          )
                        : l10n.debtBorrowedHeadline(
                            amount: formatter.format(debt.amount),
                          ),
                    style: theme.textTheme.bodyLarge?.amount,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: l10n.debtProgress(
                      repaid: formatter.format(debt.repaid),
                      total: formatter.format(debt.amount),
                    ),
                    excludeSemantics: true,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: debt.progress,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.debtProgress(
                      repaid: formatter.format(debt.repaid),
                      total: formatter.format(debt.amount),
                    ),
                    style: theme.textTheme.bodyMedium?.amount,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.debtRemainingLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatter.format(debt.remaining),
                    style: theme.textTheme.displaySmall?.amount,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusBadge(status),
                  ),
                  const SizedBox(height: 16),
                  fact(
                    l10n.startDateLabel,
                    days.formatDate(debt.startDate, today: today),
                  ),
                  if (due != null)
                    fact(l10n.dueDateLabel, days.formatDate(due, today: today)),
                  if (debt.note.isNotEmpty) fact(l10n.noteLabel, debt.note),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.repaymentsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (debt.repayments.isEmpty)
                    Text(
                      l10n.noRepayments,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    for (final repayment in debt.repayments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RepaymentRow(
                          repayment: repayment,
                          today: today,
                          onTap: () => onEditRepayment(repayment),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
        if (!debt.isSettled)
          PinnedButtonBar(
            label: l10n.addRepaymentAction,
            onPressed: onAddRepayment,
          ),
      ],
    );
  }
}

/// One repayment: "4,000.00 ₽ · 12 Oct", tappable to be changed.
class _RepaymentRow extends StatelessWidget {
  const new({
    required this.repayment,
    required this.today,
    required this.onTap,
  });

  final Repayment repayment;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.repaymentRow(
                        amount: context.moneyFormatter.format(repayment.amount),
                        date: context.dayFormatter.formatDate(
                          repayment.date,
                          today: today,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge?.amount,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
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
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox(height: 40),
          SizedBox(height: 16),
          SkeletonBox(height: 120),
          SizedBox(height: 16),
          SkeletonBox(height: 56),
          SizedBox(height: 8),
          SkeletonBox(height: 56),
        ],
      ),
    );
  }
}
