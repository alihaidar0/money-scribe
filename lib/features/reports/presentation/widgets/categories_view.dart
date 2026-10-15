import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/category_icons.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/two_columns.dart';
import 'package:money_scribe/features/reports/domain/category_spend.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';
import 'package:money_scribe/features/reports/presentation/widgets/donut_chart.dart';
import 'package:money_scribe/features/reports/presentation/widgets/parts_summary.dart';
import 'package:money_scribe/features/reports/presentation/widgets/spent_change_line.dart';

/// The colours of the slices: tonal steps of the primary, secondary and
/// tertiary tones, never the money colours (`docs/DESIGN.md`, section 2.1).
List<Color> sliceColors(ColorScheme scheme) {
  Color paler(Color color) => Color.lerp(color, scheme.surface, 0.5)!;

  return [
    scheme.primary,
    scheme.tertiary,
    scheme.secondary,
    paler(scheme.primary),
    paler(scheme.tertiary),
    paler(scheme.secondary),
  ];
}

/// RP-1 and RP-2: the spending of a month, or of one part, by category: a
/// ring with the total in its centre, how it changed since the month before,
/// and a row for each category that opens its transactions.
class CategoriesView extends StatelessWidget {
  const new({
    required this.period,
    required this.month,
    required this.scope,
    required this.spentChange,
    required this.comparedMonth,
    this.parts,
    this.onPartSelected,
    super.key,
  });

  final PeriodReport period;
  final YearMonth month;
  final PeriodScope scope;

  /// How much more (positive) or less (negative) was spent than in the same
  /// period of [comparedMonth], or `null` when it has no report.
  final Money? spentChange;

  /// The month the spending is compared with.
  final YearMonth comparedMonth;

  /// The month paid in two payments, to show a card for each part of it, or
  /// `null` for a part or a month paid once.
  final PartsReports? parts;

  /// Called with the part whose card was pressed.
  final ValueChanged<PeriodScope>? onPartSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatter = context.moneyFormatter;
    final total = period.categoriesTotal;
    final change = spentChange;

    if (period.categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          l10n.reportsNoSpending,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return TwoColumns(
      first: [
        Center(
          child: DonutChart(
            values: [
              for (final category in period.categories)
                category.amount.minorUnits,
            ],
            colors: sliceColors(theme.colorScheme),
            semanticLabel: l10n.reportsChartSemantics(
              total: formatter.format(total),
            ),
            center: Text(
              formatter.format(total),
              style: theme.textTheme.headlineSmall?.amount,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (change != null) ...[
          const SizedBox(height: 16),
          SpentChangeLine(
            change: change,
            previousMonth: comparedMonth,
            month: month,
            scope: scope,
          ),
        ],
        if (parts != null) ...[
          const SizedBox(height: 24),
          PartsSummary(parts: parts!, onPartSelected: onPartSelected),
        ],
      ],
      second: [
        for (var i = 0; i < period.categories.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LegendRow(
              category: period.categories[i],
              color: sliceColors(theme.colorScheme)[i % 6],
              permille: period.permilleOf(period.categories[i]),
              month: month,
              scope: scope,
            ),
          ),
      ],
    );
  }
}

/// A category under the ring: its icon and a dot in the colour of its slice,
/// its name, what was spent and its share. Opens its transactions.
class _LegendRow extends StatelessWidget {
  const new({
    required this.category,
    required this.color,
    required this.permille,
    required this.month,
    required this.scope,
  });

  final CategorySpend category;
  final Color color;
  final int permille;
  final YearMonth month;
  final PeriodScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final amount = context.moneyFormatter.format(category.amount);
    final share = l10n.reportsShare(
      value: '${permille ~/ 10}.${permille % 10}',
    );

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.reportsLegendSemantics(
        name: category.name,
        amount: amount,
        share: share,
      ),
      onTap: () => _open(context),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconCircle(icon: categoryIcon(category.icon), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Text(category.name, style: theme.textTheme.bodyLarge),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              amount,
                              style: theme.textTheme.titleMedium?.amount,
                              textAlign: TextAlign.end,
                            ),
                            Text(
                              share,
                              style: theme.textTheme.bodyMedium?.amount
                                  .copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    context.go(
      AppRoutes.transactionsFor(
        categoryId: category.categoryId,
        month: month,
        part: scope,
      ),
      // A new number every time, so the same row asks again even when the
      // Transactions tab already shows it.
      extra: context.read<Clock>().now().microsecondsSinceEpoch,
    );
  }
}
