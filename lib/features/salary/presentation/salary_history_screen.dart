import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';

/// SAL-6, SAL-7 and SAL-15: the saved months. Not built yet
/// (`docs/steps.md`, section 6).
class SalaryHistoryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.salaryHistoryTitle)),
      body: const ComingSoonView(),
    );
  }
}
