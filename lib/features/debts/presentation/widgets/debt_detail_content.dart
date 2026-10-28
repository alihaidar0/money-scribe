import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/widgets/debt_badges.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

/// Everything about a debt: the person, how much was lent or borrowed, how
/// much is repaid and left, where it stands, its dates and its repayments, each
/// tappable to be changed. The Debt details screen shows it, and so does the
/// detail pane of the Debts list on a wide window, with its buttons as
/// [footer].
class DebtDetailContent extends StatelessWidget {
  const new({
    required this.debt,
    required this.today,
    required this.onEditRepayment,
    this.footer = const [],
    super.key,
  });

  final Debt debt;
  final DateTime today;
  final ValueChanged<Repayment> onEditRepayment;

  /// What follows the repayments, such as the buttons of the pane.
  final List<Widget> footer;

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Semantics(
          header: true,
          child: Text(debt.person, style: theme.textTheme.headlineMedium),
        ),
        const SizedBox(height: 4),
        Text(
          lent
              ? l10n.debtLentHeadline(amount: formatter.format(debt.amount))
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
            child: LinearProgressIndicator(value: debt.progress, minHeight: 8),
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
          child: Text(l10n.repaymentsTitle, style: theme.textTheme.titleMedium),
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
        ...footer,
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
                    LucideIcons.chevronRightDir,
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
