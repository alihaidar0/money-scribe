import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/coming_soon_view.dart';

/// SAL-8 and SAL-9: two months side by side. Not built yet
/// (`docs/steps.md`, section 6).
class SalaryCompareScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.compareMonthsTitle)),
      body: const ComingSoonView(),
    );
  }
}
