import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/widgets/flow_page.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';

/// A full-screen confirmation: a large check on a soft circle, a title, one
/// sentence and one button. Used by Email verified and Password changed.
class ConfirmationPage extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = context.moneyColors.income;

    return FlowPage(
      showBackButton: false,
      centered: true,
      content: [
        Align(
          child: IconCircle(
            icon: LucideIcons.check,
            background: income.container,
            foreground: income.onContainer,
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
