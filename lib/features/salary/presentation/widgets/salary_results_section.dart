import 'package:flutter/material.dart';
import 'package:money_scribe/core/formatting/decimal_text.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// The "Results" section of the Salary screen: the calculated lines of the
/// month, or a sentence asking for the inputs while the form is not complete.
class SalaryResultsSection extends StatelessWidget {
  const new({required this.inputs, required this.result, super.key});

  final SalaryInputs? inputs;
  final SalaryResult? result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final inputs = this.inputs;
    final result = this.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.salaryResultsTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: inputs == null || result == null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.salaryResultsEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : _lines(context, inputs, result),
        ),
      ],
    );
  }

  Widget _lines(
    BuildContext context,
    SalaryInputs inputs,
    SalaryResult result,
  ) {
    final l10n = context.l10n;
    final formatter = context.moneyFormatter;
    final colors = context.moneyColors;

    return Column(
      children: [
        _ResultRow(
          title: l10n.foodAllowanceLabel,
          note: l10n.foodAllowanceNote(
            days: inputs.workingDaysInMonth,
            rate: formatter.format(inputs.foodPerDay),
          ),
          amount: formatter.formatSigned(result.foodAllowance),
          color: colors.income.color,
        ),
        const Divider(height: 1),
        _ResultRow(
          title: l10n.extraHoursPayLabel,
          note: l10n.extraHoursNote(hours: inputs.extraHoursHundredths / 100),
          amount: formatter.formatSigned(result.extraHoursPay),
          color: colors.income.color,
        ),
        const Divider(height: 1),
        _ResultRow(
          title: l10n.incomeBeforeTaxLabel,
          amount: formatter.format(result.incomeBeforeTax),
        ),
        const Divider(height: 1),
        _ResultRow(
          title: l10n.taxLabel(
            rate: DecimalText.formatHundredths(inputs.taxRateBasisPoints),
          ),
          amount: formatter.formatSigned(-result.tax),
          color: colors.expense.color,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const new({required this.title, required this.amount, this.note, this.color});

  final String title;
  final String? note;

  /// The amount, already formatted.
  final String amount;

  /// The colour of the amount; the sign says the same in words.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.bodyLarge),
                      if (note != null)
                        Text(
                          note!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // The amount is laid out first, as wide as it needs up to a
                // share of the row, and the title takes what is left.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.55,
                  ),
                  child: Text(
                    amount,
                    style: theme.textTheme.titleMedium?.amount.copyWith(
                      color: color,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
