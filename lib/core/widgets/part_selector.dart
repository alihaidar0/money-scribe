import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/payments/period_scope.dart';

/// The segmented control "Month | Part 1 | Part 2" of a month paid in two
/// payments. It chooses what a screen shows the figures of.
class PartSelector extends StatelessWidget {
  const new({required this.selected, required this.onSelected, super.key});

  final PeriodScope selected;
  final ValueChanged<PeriodScope> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PeriodScope>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: PeriodScope.month, label: Text(l10n.partMonth)),
          ButtonSegment(
            value: PeriodScope.firstPart,
            label: Text(l10n.partFirst),
          ),
          ButtonSegment(
            value: PeriodScope.secondPart,
            label: Text(l10n.partSecond),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}
