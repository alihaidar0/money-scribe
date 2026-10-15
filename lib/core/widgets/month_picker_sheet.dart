import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/formatting/western_digits.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';

/// SAL-3: the bottom sheet that chooses a month: a row of year chips, a grid of
/// months and a Done button. Closes with the chosen [YearMonth], or with
/// `null` when dismissed.
///
/// No future month is offered: [last], the month of today, is the latest one.
/// The years are the last three up to the year of [last] (more when [selected]
/// is older), and the year of [last] has only its months up to [last].
Future<YearMonth?> showMonthPickerSheet(
  BuildContext context, {
  required YearMonth selected,
  required YearMonth last,
}) {
  return showModalBottomSheet<YearMonth>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) =>
        _MonthPickerSheet(selected: selected, last: last),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  const new({required this.selected, required this.last});

  final YearMonth selected;
  final YearMonth last;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = widget.selected.year;
  late int _month = widget.selected.month;

  /// The latest month of [year] that can be chosen.
  int _lastMonthOf(int year) =>
      year == widget.last.year ? widget.last.month : 12;

  void _selectYear(int year) {
    setState(() {
      _year = year;
      // The year of today stops at today's month.
      if (_month > _lastMonthOf(year)) _month = _lastMonthOf(year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final months = context.monthFormatter;
    final lastYear = widget.last.year;
    final firstYear = widget.selected.year < lastYear - 2
        ? widget.selected.year
        : lastYear - 2;

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
                for (var year = firstYear; year <= lastYear; year++)
                  ChoiceChip(
                    label: Text(WesternDigits.normalize('$year')),
                    selected: year == _year,
                    showCheckmark: false,
                    onSelected: (_) => _selectYear(year),
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
                for (var month = 1; month <= _lastMonthOf(_year); month++)
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
