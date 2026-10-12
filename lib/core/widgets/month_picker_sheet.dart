import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';

/// SAL-3: the bottom sheet that chooses a month: a row of year chips, a grid of
/// the twelve months and a Done button. Closes with the chosen [YearMonth], or
/// with `null` when dismissed. The years offered are the one of [selected]
/// and the one before and after it.
Future<YearMonth?> showMonthPickerSheet(
  BuildContext context, {
  required YearMonth selected,
}) {
  return showModalBottomSheet<YearMonth>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => _MonthPickerSheet(selected: selected),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  const new({required this.selected});

  final YearMonth selected;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = widget.selected.year;
  late int _month = widget.selected.month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final months = context.monthFormatter;
    final firstYear = widget.selected.year - 1;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.chooseMonthTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var year = firstYear; year <= firstYear + 2; year++)
                  ChoiceChip(
                    label: Text(WesternDigits.normalize('$year')),
                    selected: year == _year,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _year = year),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 48,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var month = 1; month <= 12; month++)
                  _MonthButton(
                    label: months.shortName(month),
                    semanticLabel: months.fullName(month),
                    selected: month == _month,
                    onPressed: () => setState(() => _month = month),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(YearMonth(_year, _month)),
              child: Text(l10n.doneAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// One month of the grid: a filled pill when chosen, an outlined one otherwise.
class _MonthButton extends StatelessWidget {
  const new({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, maxLines: 1);

    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: true,
      excludeSemantics: true,
      onTap: onPressed,
      child: selected
          ? FilledButton.tonal(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}
