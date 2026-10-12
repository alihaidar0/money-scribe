import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_summary.dart';

/// The card pinned under the list of fixed items: the balance the pay leaves
/// once they are counted, the sum it comes from and, for a month paid in two
/// payments, the balance of the whole month.
class FixedItemsSummaryCard extends StatelessWidget {
  const new({
    required this.summary,
    required this.items,
    required this.twoPayments,
    required this.part,
    super.key,
  });

  final FixedItemsSummary summary;

  /// The items the sum is made of: the ones on the screen.
  final List<FixedItem> items;
  final bool twoPayments;
  final FixedItemPart part;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatter = context.moneyFormatter;
    final wholeMonth = summary.wholeMonth;

    final label = twoPayments
        ? l10n.fixedItemsBalancePartLabel(
            part: part == FixedItemPart.first
                ? l10n.partFirst
                : l10n.partSecond,
          )
        : l10n.fixedItemsBalanceLabel;
    final term = twoPayments ? l10n.fixedItemsPayTerm : l10n.salaryTitle;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    String balance(Money money) {
      return money.isNegative
          ? formatter.formatSigned(money)
          : formatter.format(money);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              balance(summary.balance),
              style: theme.textTheme.headlineSmall?.amount,
            ),
            const SizedBox(height: 4),
            Text(_sum(context, term), style: secondary),
            if (wholeMonth != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.fixedItemsWholeMonth(amount: balance(wholeMonth)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Salary 104,400.00 ₽ + Scholarship 5,000.00 ₽ − Rent 30,000.00 ₽". A
  /// line only breaks between the terms, so a name stays with its amount.
  String _sum(BuildContext context, String term) {
    const noBreakSpace = ' ';
    final formatter = context.moneyFormatter;
    final text = StringBuffer(
      '$term$noBreakSpace${formatter.format(summary.pay)}',
    );
    for (final item in items) {
      final sign = item.kind == FixedItemKind.income ? '+' : '−';
      text.write(
        ' $sign$noBreakSpace${item.name}$noBreakSpace'
        '${formatter.format(item.amount)}',
      );
    }
    return text.toString();
  }
}
