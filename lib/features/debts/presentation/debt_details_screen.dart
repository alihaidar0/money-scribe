import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/leave_screen.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/pinned_button_bar.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/debts/bloc/debt_details_bloc.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';
import 'package:money_scribe/features/debts/presentation/widgets/debt_detail_content.dart';
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
      startDate: debt.startDate,
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
      startDate: debt.startDate,
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
          previous.failedAction != current.failedAction ||
          previous.refusal != current.refusal ||
          previous.changedElsewhere != current.changedElsewhere,
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
        final refusal = state.refusal;
        if (refusal != null) {
          final remaining = state.refusedRemaining;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(switch (refusal) {
                  DebtRefusal.repaymentLimitReached =>
                    l10n.repaymentLimitReached,
                  DebtRefusal.exceedsRemaining when remaining != null =>
                    l10n.repaymentTooHigh(
                      remaining: context.moneyFormatter.format(remaining),
                    ),
                  DebtRefusal.repaymentBeforeStart => l10n.repaymentBeforeStart,
                  DebtRefusal.dateOutOfRange => l10n.debtDateOutOfRange,
                  _ => l10n.couldNotSave,
                }),
              ),
            );
        }
        if (state.changedElsewhere) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.debtChangedElsewhere)));
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
        // Outside the body, so a message that appears at the bottom sits above
        // the button instead of covering it.
        bottomNavigationBar: BlocBuilder<DebtDetailsBloc, DebtDetailsState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.debt?.isSettled != current.debt?.isSettled,
          builder: (context, state) =>
              state.status == DebtDetailsStatus.ready && !state.debt!.isSettled
              ? PinnedButtonBar(
                  label: l10n.addRepaymentAction,
                  onPressed: () => _addRepayment(context),
                )
              : const SizedBox.shrink(),
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
            DebtDetailsStatus.ready => DebtDetailContent(
              debt: state.debt!,
              today: state.today,
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
