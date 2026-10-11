import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';

/// FIX-1 and FIX-2: the recurring income and costs. Not built yet
/// (`docs/steps.md`, section 6).
class FixedItemsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.fixedItemsTitle)),
      body: const ComingSoonView(),
    );
  }
}
