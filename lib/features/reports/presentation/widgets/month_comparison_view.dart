import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';
import 'package:money_scribe/features/reports/presentation/widgets/parts_summary.dart';

/// The height of the tallest bar.
const _barAreaHeight = 160.0;

/// The name of a period in the comparison: "October 2026", or "Part 1 ·
/// October 2026" for a part of the month.
String _periodName(BuildContext context, YearMonth month, PeriodScope scope) {
  final l10n = context.l10n;
  final name = context.monthFormatter.format(month);

  return switch (scope) {
    PeriodScope.month => name,
    PeriodScope.firstPart => l10n.reportsPartMonth(
      part: l10n.partFirst,
      month: name,
    ),
    PeriodScope.secondPart => l10n.reportsPartMonth(
      part: l10n.partSecond,
      month: name,
    ),
  };
}

/// RP-3 and RP-4: a month (or one part of it) against the same period of the
/// month before: grouped bars for the income and the spending, and under them
/// a table with the same figures and the difference.
class MonthComparisonView extends StatelessWidget {
  const new({
    required this.month,
    required this.comparedMonth,
    required this.scope,
    required this.current,
    required this.previous,
    this.parts,
    this.onPartSelected,
    super.key,
  });

  final YearMonth month;

  /// The month [month] is compared with.
  final YearMonth comparedMonth;
  final PeriodScope scope;
  final PeriodReport current;

  /// The same period of [comparedMonth], or `null` when there is none.
  final PeriodReport? previous;

  /// The month paid in two payments, to show a card for each part of it, or
  /// `null` for a part or a month paid once.
  final PartsReports? parts;

  /// Called with the part whose card was pressed.
  final ValueChanged<PeriodScope>? onPartSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final before = previous;

    if (before == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          l10n.reportsNoPreviousMonth(
            month: context.monthFormatter.format(comparedMonth),
          ),
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final previousName = _periodName(context, comparedMonth, scope);
    final currentName = _periodName(context, month, scope);
    final lines = [
      _Line(
        label: l10n.overviewIncome,
        previous: before.income,
        current: current.income,
      ),
      _Line(
        label: l10n.overviewSpent,
        previous: before.spent,
        current: current.spent,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupedBars(lines: lines),
        const SizedBox(height: 12),
        _BarsLegend(previousName: previousName, currentName: currentName),
        const SizedBox(height: 16),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LineCard(
              line: line,
              previousName: previousName,
              currentName: currentName,
            ),
          ),
        if (parts != null) ...[
          const SizedBox(height: 12),
          PartsSummary(parts: parts!, onPartSelected: onPartSelected),
        ],
      ],
    );
  }
}

/// One line of the comparison, such as the income, in the two periods.
class _Line {
  const new({
    required this.label,
    required this.previous,
    required this.current,
  });

  final String label;
  final Money previous;
  final Money current;

  Money get difference => current - previous;
}

/// The colour of the bars of the month before and of the month shown: two
/// tonal steps, never the money colours.
Color _previousColor(ColorScheme scheme) => scheme.tertiary;
Color _currentColor(ColorScheme scheme) => scheme.primary;

/// Two bars for each line: the month before, then the month shown. The
/// figures are in the table under the bars, so the bars carry no text.
class _GroupedBars extends StatelessWidget {
  const new({required this.lines});

  final List<_Line> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tallest = lines.fold<int>(
      0,
      (most, line) => math.max(
        most,
        math.max(line.previous.minorUnits, line.current.minorUnits),
      ),
    );

    double height(Money money) {
      if (tallest == 0 || money.minorUnits <= 0) return 0;
      // A tiny amount still shows as a sliver.
      return math.max(money.minorUnits / tallest * _barAreaHeight, 4);
    }

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final line in lines)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: _barAreaHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Bar(
                              height: height(line.previous),
                              color: _previousColor(theme.colorScheme),
                            ),
                            const SizedBox(width: 8),
                            _Bar(
                              height: height(line.current),
                              color: _currentColor(theme.colorScheme),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(line.label, style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const new({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: SizedBox(width: 36, height: height),
    );
  }
}

/// Which bar is which period.
class _BarsLegend extends StatelessWidget {
  const new({required this.previousName, required this.currentName});

  final String previousName;
  final String currentName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendItem(color: _previousColor(scheme), label: previousName),
        _LegendItem(color: _currentColor(scheme), label: currentName),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const new({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const SizedBox.square(dimension: 12),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

/// A line of the table: its two figures and the difference, each on a row of
/// its own so nothing is cut off at a large text size.
class _LineCard extends StatelessWidget {
  const new({
    required this.line,
    required this.previousName,
    required this.currentName,
  });

  final _Line line;
  final String previousName;
  final String currentName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatter = context.moneyFormatter;
    final difference = formatter.formatSigned(line.difference);

    return Semantics(
      container: true,
      label: l10n.reportsComparisonSemantics(
        line: line.label,
        previousPeriod: previousName,
        previousValue: formatter.format(line.previous),
        currentPeriod: currentName,
        currentValue: formatter.format(line.current),
        difference: difference,
      ),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(line.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _FigureRow(
                label: previousName,
                value: formatter.format(line.previous),
              ),
              _FigureRow(
                label: currentName,
                value: formatter.format(line.current),
              ),
              const Divider(height: 24),
              _FigureRow(
                label: l10n.compareDifferenceColumn,
                value: difference,
                emphasised: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigureRow extends StatelessWidget {
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
