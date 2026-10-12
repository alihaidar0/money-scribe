import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/widgets/debt_badges.dart';
import 'package:money_scribe/core/widgets/debt_summary_row.dart';
import 'package:money_scribe/core/widgets/two_columns.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';

/// RP-5: where the debts stand: what is owed to the person and what they owe,
/// then the overdue debts and the open ones. A row opens the debt.
class DebtsView extends StatelessWidget {
  const new({required this.report, required this.today, super.key});

  final DebtsReport report;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebtSummaryRow(owedToYou: report.owedToYou, youOwe: report.youOwe),
        const SizedBox(height: 16),
        if (report.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              l10n.noOpenDebts,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        TwoColumns(
          first: [
            if (report.overdue.isNotEmpty)
              _Section(
                title: l10n.reportsOverdueSection(count: report.overdue.length),
                items: report.overdue,
                today: today,
              ),
          ],
          second: [
            if (report.open.isNotEmpty)
              _Section(
                title: l10n.reportsOpenSection(count: report.open.length),
                items: report.open,
                today: today,
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const new({required this.title, required this.items, required this.today});

  final String title;
  final List<DebtReportItem> items;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DebtRow(item: item, today: today),
            ),
        ],
      ),
    );
  }
}

/// A debt: the person and whether it was lent or borrowed, what is left to
/// repay, its due day and where it stands.
class _DebtRow extends StatelessWidget {
  const new({required this.item, required this.today});

  final DebtReportItem item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.moneyColors;
    final due = item.dueDate;
    final lent = item.direction == DebtDirection.lent;

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.debtDetailsPath(item.id)),
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
                    Text(item.person, style: theme.textTheme.titleMedium),
                    Text(
                      context.moneyFormatter.format(item.remaining),
                      style: theme.textTheme.titleMedium?.amount.copyWith(
                        color: lent ? colors.lent.color : colors.borrowed.color,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        DirectionBadge(item.direction),
                        StatusBadge(item.status),
                      ],
                    ),
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
