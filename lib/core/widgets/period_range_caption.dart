import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';

/// The days the chosen period covers, such as "20 Oct – 4 Nov", in a small
/// line under the choice between the month and its parts. A year is added to a
/// day that is not in this year.
class PeriodRangeCaption extends StatelessWidget {
  const new({required this.range, required this.today, super.key});

  final PayPeriod range;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = context.dayFormatter;
    final theme = Theme.of(context);

    return Text(
      context.l10n.periodRangeLabel(
        from: days.formatDate(range.start, today: today),
        to: days.formatDate(range.end, today: today),
      ),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
