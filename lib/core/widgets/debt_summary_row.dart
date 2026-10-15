import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';

/// "Owed to you" and "You owe", side by side while there is room.
class DebtSummaryRow extends StatelessWidget {
  const new({required this.owedToYou, required this.youOwe, super.key});

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
