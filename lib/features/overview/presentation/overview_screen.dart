import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';

/// OV-1 and OV-2: the Overview. Not built yet (`docs/steps.md`, section 6).
class OverviewScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return TopLevelScreen(
      title: context.l10n.overviewTitle,
      body: const ComingSoonView(),
    );
  }
}
