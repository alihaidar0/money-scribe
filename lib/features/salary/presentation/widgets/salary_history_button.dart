import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';

/// The History icon in the app bar of the Salary screen: opens the saved
/// months.
class SalaryHistoryButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.history),
      tooltip: context.l10n.salaryHistoryTitle,
      onPressed: () => context.push(AppRoutes.salaryHistory),
    );
  }
}
