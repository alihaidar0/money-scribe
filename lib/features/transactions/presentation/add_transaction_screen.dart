import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';

/// TX-4: the form for a new transaction. Not built yet (`docs/steps.md`,
/// section 6).
class AddTransactionScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addTransactionTitle)),
      body: const ComingSoonView(),
    );
  }
}
