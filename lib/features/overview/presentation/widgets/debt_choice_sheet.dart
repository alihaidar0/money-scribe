import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/widgets/debt_badges.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/overview/bloc/debt_choice_bloc.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';

/// OV-4: the sheet that asks which debt a repayment is for. Closes with the
/// chosen [DebtChoice], or with `null` when cancelled.
Future<DebtChoice?> showDebtChoiceSheet(BuildContext context) {
  return showModalBottomSheet<DebtChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) =>
          DebtChoiceBloc(repository: context.read<OverviewRepository>())
            ..add(const DebtChoiceStarted()),
      child: const _DebtChoiceSheet(),
    ),
  );
}

class _DebtChoiceSheet extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.chooseDebtTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<DebtChoiceBloc, DebtChoiceState>(
              builder: (context, state) => switch (state.status) {
                DebtChoiceStatus.loading => const SkeletonScope(
                  child: Column(
                    children: [
                      SkeletonBox(),
                      SizedBox(height: 8),
                      SkeletonBox(),
                    ],
                  ),
                ),
                DebtChoiceStatus.ready when state.debts.isEmpty => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.noOpenDebts,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                DebtChoiceStatus.ready => Column(
                  children: [
                    for (final debt in state.debts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DebtRow(debt: debt),
                      ),
                  ],
                ),
                DebtChoiceStatus.noConnection => FailureView(
                  kind: FailureKind.noConnection,
                  onRetry: () => context.read<DebtChoiceBloc>().add(
                    const DebtChoiceStarted(),
                  ),
                ),
                DebtChoiceStatus.failure => FailureView(
                  kind: FailureKind.error,
                  onRetry: () => context.read<DebtChoiceBloc>().add(
                    const DebtChoiceStarted(),
                  ),
                ),
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const new({required this.debt});

  final DebtChoice debt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(debt),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.person, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        l10n.debtRemaining(
                          amount: context.moneyFormatter.format(debt.remaining),
                        ),
                        style: theme.textTheme.bodyMedium?.amount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DirectionBadge(debt.direction),
                    const SizedBox(height: 4),
                    StatusBadge(debt.status),
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
