import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/features/salary/domain/salary_comparison.dart';

/// Shown instead of a figure the month does not have.
const _missing = '—';

const _cardPadding = 16.0;
const _columnGap = 8.0;

/// The narrowest the first column (the name of a line) may get, before the
/// text size is applied.
const _minLineColumn = 56.0;

/// The figures of the side-by-side table: the small label size, so four columns
/// fit a phone.
TextStyle? _compactFigureStyle(ThemeData theme) {
  return theme.textTheme.labelMedium?.amount;
}

/// The comparison of two months: a card with a row for each line and the
/// columns Line, [left], [right] and Difference. When the figures do not fit
/// side by side, for example at a large text size, each line becomes a block
/// with one row for each figure, so nothing is cut off.
class SalaryCompareTable extends StatelessWidget {
  const new({
    required this.lines,
    required this.left,
    required this.right,
    super.key,
  });

  final List<ComparisonLine> lines;
  final YearMonth left;
  final YearMonth right;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _rows(context);
    final months = context.monthFormatter;
    final sameName =
        months.fullName(left.month) == months.fullName(right.month);
    final leftName = sameName
        ? months.format(left)
        : months.fullName(left.month);
    final rightName = sameName
        ? months.format(right)
        : months.fullName(right.month);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _cardPadding,
          vertical: 12,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnWidth = _figureColumnWidth(context, rows, [
              leftName,
              rightName,
              context.l10n.compareDifferenceColumn,
            ]);
            final scaler = MediaQuery.textScalerOf(context);
            final needed =
                scaler.scale(_minLineColumn) + 3 * (columnWidth + _columnGap);

            return constraints.maxWidth >= needed
                ? _SideBySide(
                    rows: rows,
                    columnWidth: columnWidth,
                    leftName: leftName,
                    rightName: rightName,
                  )
                : _Stacked(
                    rows: rows,
                    leftName: leftName,
                    rightName: rightName,
                  );
          },
        ),
      ),
    );
  }

  List<_Row> _rows(BuildContext context) {
    final l10n = context.l10n;
    final formatter = context.moneyFormatter;
    final months = context.monthFormatter;
    final leftMonth = months.format(left);
    final rightMonth = months.format(right);

    /// A fixed-items figure always has its sign; any other has one only when
    /// it is negative.
    String text(ComparisonLine line, Money money) {
      return line.kind == ComparisonLineKind.fixedItems || money.isNegative
          ? formatter.formatSigned(money)
          : formatter.format(money);
    }

    String figure(ComparisonLine line, Money? money) =>
        money == null ? _missing : text(line, money);
    String spoken(ComparisonLine line, Money? money) =>
        money == null ? l10n.compareNotSaved : text(line, money);

    _Row row(ComparisonLine line) {
      final label = _label(l10n, line.kind);
      final difference = line.difference;

      return _Row(
        label: label,
        left: figure(line, line.left),
        right: figure(line, line.right),
        difference: difference == null
            ? _missing
            : formatter.formatSigned(difference),
        semantics: difference == null
            ? l10n.compareLineSemanticsNoDifference(
                line: label,
                leftMonth: leftMonth,
                leftValue: spoken(line, line.left),
                rightMonth: rightMonth,
                rightValue: spoken(line, line.right),
              )
            : l10n.compareLineSemantics(
                line: label,
                leftMonth: leftMonth,
                leftValue: spoken(line, line.left),
                rightMonth: rightMonth,
                rightValue: spoken(line, line.right),
                difference: formatter.formatSigned(difference),
              ),
      );
    }

    return [for (final line in lines) row(line)];
  }

  static String _label(AppLocalizations l10n, ComparisonLineKind kind) {
    return switch (kind) {
      ComparisonLineKind.incomeBeforeTax => l10n.incomeBeforeTaxLabel,
      ComparisonLineKind.tax => l10n.compareTaxLabel,
      ComparisonLineKind.totalAfterTax => l10n.salaryTotalAfterTax,
      ComparisonLineKind.payAfterTax => l10n.comparePayAfterTaxLabel,
      ComparisonLineKind.fixedItems => l10n.fixedItemsTitle,
      ComparisonLineKind.balanceAfterFixedItems => l10n.fixedItemsBalanceLabel,
    };
  }

  /// The width of a column of figures: the widest figure or the longest word
  /// of a heading, at the current text size.
  static double _figureColumnWidth(
    BuildContext context,
    List<_Row> rows,
    List<String> headings,
  ) {
    final theme = Theme.of(context);
    final figureStyle = _compactFigureStyle(theme)
        ?.copyWith(fontWeight: FontWeight.w600);
    final headingStyle = theme.textTheme.labelMedium;

    var widest = 0.0;
    for (final row in rows) {
      for (final text in [row.left, row.right, row.difference]) {
        widest = math.max(widest, _width(context, text, figureStyle));
      }
    }
    for (final heading in headings) {
      for (final word in heading.split(' ')) {
        widest = math.max(widest, _width(context, word, headingStyle));
      }
    }
    return widest.ceilToDouble() + 1;
  }

  static double _width(BuildContext context, String text, TextStyle? style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// One line of the comparison, already formatted.
class _Row {
  const new({
    required this.label,
    required this.left,
    required this.right,
    required this.difference,
    required this.semantics,
  });

  final String label;
  final String left;
  final String right;
  final String difference;

  /// What a screen reader says for the whole row.
  final String semantics;
}

/// The four columns in a row each; the heading row first.
class _SideBySide extends StatelessWidget {
  const new({
    required this.rows,
    required this.columnWidth,
    required this.leftName,
    required this.rightName,
  });

  final List<_Row> rows;
  final double columnWidth;
  final String leftName;
  final String rightName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final figureStyle = _compactFigureStyle(theme);

    Widget line(List<String> cells, TextStyle? style, {TextStyle? last}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(cells[0], style: style)),
          for (var i = 1; i < cells.length; i++) ...[
            const SizedBox(width: _columnGap),
            SizedBox(
              width: columnWidth,
              child: Text(
                cells[i],
                style: i == cells.length - 1 ? last ?? style : style,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: line([
            l10n.compareLineColumn,
            leftName,
            rightName,
            l10n.compareDifferenceColumn,
          ], headingStyle),
        ),
        for (final row in rows) ...[
          const Divider(height: 24),
          Semantics(
            container: true,
            label: row.semantics,
            excludeSemantics: true,
            child: line(
              [row.label, row.left, row.right, row.difference],
              figureStyle,
              last: figureStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

/// A block for each line: its name, then a row for each figure.
class _Stacked extends StatelessWidget {
  const new({
    required this.rows,
    required this.leftName,
    required this.rightName,
  });

  final List<_Row> rows;
  final String leftName;
  final String rightName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          Semantics(
            container: true,
            label: rows[i].semantics,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(rows[i].label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _Figure(name: leftName, value: rows[i].left),
                const SizedBox(height: 4),
                _Figure(name: rightName, value: rows[i].right),
                const SizedBox(height: 4),
                _Figure(
                  name: l10n.compareDifferenceColumn,
                  value: rows[i].difference,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A month's figure in a stacked line: its name at the start and the amount at
/// the end. When both do not fit on one line the amount goes under the name, so
/// neither is cut off.
class _Figure extends StatelessWidget {
  const new({required this.name, required this.value, this.bold = false});

  final String name;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 2,
      children: [
        Text(
          name,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.amount.copyWith(
            fontWeight: bold ? FontWeight.w600 : null,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
