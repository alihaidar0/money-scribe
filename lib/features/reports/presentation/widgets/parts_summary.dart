import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';

/// The two parts of a month paid in two payments, each with the same part of
/// the month it is compared with (when there is one).
final class PartsReports {
  const new({
    required this.first,
    required this.second,
    this.previousFirst,
    this.previousSecond,
  });

  final PeriodReport first;
  final PeriodReport second;
  final PeriodReport? previousFirst;
  final PeriodReport? previousSecond;
}

/// A card for each part of a month paid in two payments, so both can be seen
/// at once: what came in and what was spent in it, and how the spending
/// changed since the same part of the month it is compared with. A card shows
/// that part when pressed.
class PartsSummary extends StatelessWidget {
  const new({required this.parts, this.onPartSelected, super.key});

  final PartsReports parts;
  final ValueChanged<PeriodScope>? onPartSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = [
      _PartCard(
        scope: PeriodScope.firstPart,
        title: l10n.periodFirstPart,
        part: l10n.partFirst,
        report: parts.first,
        previous: parts.previousFirst,
        onPressed: onPartSelected,
      ),
      _PartCard(
        scope: PeriodScope.secondPart,
        title: l10n.periodSecondPart,
        part: l10n.partSecond,
        report: parts.second,
        previous: parts.previousSecond,
        onPressed: onPartSelected,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.reportsByPart,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        for (final card in cards)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
      ],
    );
  }
}

class _PartCard extends StatelessWidget {
  const new({
    required this.scope,
    required this.title,
    required this.part,
    required this.report,
    required this.previous,
    required this.onPressed,
  });

  final PeriodScope scope;
  final String title;
  final String part;
  final PeriodReport report;
  final PeriodReport? previous;
  final ValueChanged<PeriodScope>? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatter = context.moneyFormatter;
    final previous = this.previous;
    final change = previous == null ? null : report.spent - previous.spent;
    final onPressed = this.onPressed;

    return Semantics(
      button: onPressed != null,
      excludeSemantics: true,
      label: l10n.reportsPartSemantics(
        part: part,
        income: formatter.format(report.income),
        spent: formatter.format(report.spent),
      ),
      onTap: onPressed == null ? null : () => onPressed(scope),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed == null ? null : () => onPressed(scope),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _Figure(
                  label: l10n.overviewIncome,
                  value: formatter.format(report.income),
                ),
                _Figure(
                  label: l10n.overviewSpent,
                  value: formatter.format(report.spent),
                  emphasised: true,
                ),
                if (change != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            change.isNegative
                                ? LucideIcons.arrowDown
                                : change.isPositive
                                ? LucideIcons.arrowUp
                                : LucideIcons.minus,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatter.formatSigned(change),
                            style: theme.textTheme.bodyMedium?.amount.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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

class _Figure extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style:
                (emphasised
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.bodyLarge)
                    ?.amount,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}
