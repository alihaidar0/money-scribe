import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';

/// The two segments of the Salary tab.
enum SalarySection { month, fixedItems }

/// The segmented control "Month | Fixed items" at the top of the Salary tab.
/// Choosing the other segment goes to its page, which keeps the navigation bar.
/// With a [month] the other page shows that month, otherwise the month of
/// today.
class SalarySectionSwitch extends StatelessWidget {
  const new({required this.selected, this.month, super.key});

  final SalarySection selected;
  final YearMonth? month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: double.infinity,
      child: PillSegmentedButton<SalarySection>(
        segments: [
          ButtonSegment(
            value: SalarySection.month,
            label: Text(l10n.partMonth),
          ),
          ButtonSegment(
            value: SalarySection.fixedItems,
            label: Text(l10n.fixedItemsTitle),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (selection) {
          final section = selection.first;
          if (section == selected) return;
          context.go(switch (section) {
            SalarySection.month => AppRoutes.salaryTab(month),
            SalarySection.fixedItems => AppRoutes.fixedItemsTab(month),
          });
        },
      ),
    );
  }
}
