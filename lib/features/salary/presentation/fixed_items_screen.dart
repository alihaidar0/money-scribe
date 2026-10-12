import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_history_button.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_section_switch.dart';

/// FIX-1 and FIX-2: the recurring income and costs, the second segment of the
/// Salary screen. Not built yet (`docs/steps.md`, section 6).
class FixedItemsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return TopLevelScreen(
      title: context.l10n.salaryTitle,
      actions: const [SalaryHistoryButton()],
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: SalarySectionSwitch(selected: SalarySection.fixedItems),
          ),
          // Scrolls, so a large text size never overflows.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: const ComingSoonView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
