import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';

/// SAL-1c: asks whether to delete a saved [month]. Answers `true` for Delete,
/// `false` for Cancel or a tap outside. Delete is in the error colours.
Future<bool> confirmDeleteMonth(
  BuildContext context, {
  required YearMonth month,
}) async {
  final l10n = context.l10n;
  final name = context.monthFormatter.format(month);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(l10n.deleteMonthTitle(month: name)),
        content: Text(l10n.deleteMonthMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Asks whether to leave a saved [month] that has unsaved changes. Answers
/// `true` for Discard, `false` for Keep editing or a tap outside.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  required YearMonth month,
}) async {
  final l10n = context.l10n;
  final name = context.monthFormatter.format(month);

  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.discardChangesTitle),
      content: Text(l10n.discardChangesMessage(month: name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.keepEditingAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.discardAction),
        ),
      ],
    ),
  );
  return discard ?? false;
}
