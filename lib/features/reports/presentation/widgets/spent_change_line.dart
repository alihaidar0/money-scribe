import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';

/// "vs September −3,200.00 ₽": how much more or less was spent than in the
/// same period of the month before, with an arrow that points the same way.
class SpentChangeLine extends StatelessWidget {
  const new({
    required this.change,
    required this.previousMonth,
    required this.month,
    required this.scope,
    super.key,
  });

  final Money change;
  final YearMonth previousMonth;
  final YearMonth month;
  final PeriodScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final months = context.monthFormatter;
    // The year only matters when the month before is in another year.
    final monthName = previousMonth.year == month.year
        ? months.fullName(previousMonth.month)
        : months.format(previousMonth);
    final period = switch (scope) {
      PeriodScope.month => monthName,
      PeriodScope.firstPart => '$monthName ${l10n.partFirst}',
      PeriodScope.secondPart => '$monthName ${l10n.partSecond}',
    };
    final icon = change.isNegative
        ? Icons.arrow_downward
        : change.isPositive
        ? Icons.arrow_upward
        : Icons.remove;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            l10n.reportsVsPrevious(
              period: period,
              change: context.moneyFormatter.formatSigned(change),
            ),
            style: theme.textTheme.bodyMedium?.amount.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
