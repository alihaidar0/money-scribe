import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';

/// TX-1 and TX-2: the Transactions screen. Not built yet (`docs/steps.md`,
/// section 6).
class TransactionsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return TopLevelScreen(
      title: context.l10n.transactionsTitle,
      body: const ComingSoonView(),
    );
  }
}
