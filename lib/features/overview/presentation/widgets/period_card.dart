import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';

/// The tonal card of one part of a month paid in two payments: its balance
/// and three small figures. It opens the transactions of that part.
class PeriodCard extends StatelessWidget {
  const new({
    required this.title,
    required this.figures,
    required this.onTap,
    super.key,
  });

  final String title;
  final OverviewFigures figures;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatter = context.moneyFormatter;

    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${l10n.overviewBalance} '),
                            TextSpan(
                              text: formatter.format(figures.balance),
                              style: theme.textTheme.titleLarge?.amount,
                            ),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _Figure(l10n.overviewIncome, figures.income),
                          _Figure(l10n.overviewSpent, figures.spent),
                          _Figure(l10n.debtsTitle, figures.debtMovements),
                        ],
                      ),
                    ],
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
    );
  }
}

/// "Income +43,500.00 ₽": a label and an amount in the colour of its sign.
class _Figure extends StatelessWidget {
  const new(this.label, this.amount);

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = amount.isNegative
        ? context.moneyColors.expense.color
        : context.moneyColors.income.color;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          TextSpan(
            text: context.moneyFormatter.formatSigned(amount),
            style: theme.textTheme.labelLarge?.amount.copyWith(color: color),
          ),
        ],
      ),
      style: theme.textTheme.bodyMedium,
    );
  }
}
