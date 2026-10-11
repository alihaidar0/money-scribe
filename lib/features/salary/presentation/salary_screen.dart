import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';

/// SAL-1 and SAL-2: the Salary screen. Not built yet (`docs/steps.md`,
/// section 6).
class SalaryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return TopLevelScreen(
      title: context.l10n.salaryTitle,
      body: const ComingSoonView(),
    );
  }
}
